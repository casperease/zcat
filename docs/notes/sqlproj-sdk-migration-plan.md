# Migration plan: Legacy SSDT .sqlproj to SDK-style Microsoft.Build.Sql

## Why

The legacy `.sqlproj` format requires Visual Studio and the SSDT workload installed.
The build target `Microsoft.Data.Tools.Schema.SqlTasks.targets` is a VS component
that does not ship with the dotnet CLI, so `dotnet build` fails with MSB4278.

SDK-style projects using `Microsoft.Build.Sql` build with `dotnet build` on any
platform (Windows, Linux, macOS) with no VS dependency. The output is the same
`.dacpac` artifact, deployable with `sqlpackage` as before.

## Current state

- Microsoft.Build.Sql **2.1.0** is the latest stable release (GA since 1.0.0, March 2025).
- Supported in VS Code, CLI, and VS 2022 (SDK-style SSDT preview workload).
- **Not** supported in classic SSDT / VS 2022 original SQL project mode — the conversion is one-way.

## Step-by-step

### 1. Preparation

- [ ] Back up the original `.sqlproj` (copy it, or rely on git history).
- [ ] Build the original project in Visual Studio to produce a reference `.dacpac`.
      Keep this artifact — you will compare against it after conversion.
- [ ] Install the verification tool:

      ```text
      dotnet tool install --global Microsoft.DacpacVerify
      ```

### 2. Convert the .sqlproj

Open the `.sqlproj` in a text editor. The goal is to strip it down to the SDK-style
minimum and let the SDK handle the rest.

**a) Add the SDK declaration.** Change the `<Project>` element:

    ```xml
    <!-- Before -->
    <Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003" ToolsVersion="4.0">

    <!-- After -->
    <Project DefaultTargets="Build">
    <Sdk Name="Microsoft.Build.Sql" Version="2.1.0" />
    ```

**b) Remove SSDT imports.** Delete all `<Import>` elements referencing:

- `Microsoft.Data.Tools.Schema.SqlTasks.targets`
- `Microsoft.Common.props`
- `$(SqlCmdTargetsFilePath)` or similar SSDT paths
- The entire Visual Studio version detection block (`SSDTExists`, `VisualStudioVersion`, etc.)

**c) Remove auto-globbed items.** Delete all `<Build Include="..." />` entries for `.sql`
files. The SDK auto-includes all `**/*.sql` files. Leaving them in causes duplicate
build items and errors.

**d) Remove boilerplate items.** Delete:

- `<Folder Include="Properties" />`
- Default `Debug` / `Release` PropertyGroups (unless you have custom settings in them)

**e) Keep what matters.** The resulting `.sqlproj` should look roughly like:

    ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <Project DefaultTargets="Build">
    <Sdk Name="Microsoft.Build.Sql" Version="2.1.0" />
    <PropertyGroup>
        <Name>YourDatabaseName</Name>
        <DSP>Microsoft.Data.Tools.Schema.Sql.Sql160DatabaseSchemaProvider</DSP>
        <!-- any SQLCMD variables, QueryStoreDesiredState, etc. you had -->
    </PropertyGroup>

    <!-- Pre/post-deploy scripts (if any) -->
    <ItemGroup>
        <PreDeploy Include="Script.PreDeployment.sql" />
        <PostDeploy Include="Script.PostDeployment.sql" />
    </ItemGroup>

    <!-- Database references -->
    <ItemGroup>
        <!-- system databases are now NuGet packages -->
        <PackageReference Include="Microsoft.SqlServer.Dacpacs.Master" Version="160.2.1" />
        <!-- project-to-project refs still work -->
        <ProjectReference Include="..\OtherDb\OtherDb.sqlproj" />
    </ItemGroup>

    <!-- Exclude scripts pulled in via :r from pre/post-deploy -->
    <ItemGroup>
        <Build Remove="Scripts\SeedData\**" />
        <None Include="Scripts\SeedData\**" />
    </ItemGroup>
    </Project>
    ```

### 3. DSP reference

Pick the DSP matching your target SQL Server version:

| Target                        | DSP value                                                            |
| ----------------------------- | -------------------------------------------------------------------- |
| SQL Server 2014               | `Microsoft.Data.Tools.Schema.Sql.Sql120DatabaseSchemaProvider`       |
| SQL Server 2016               | `Microsoft.Data.Tools.Schema.Sql.Sql130DatabaseSchemaProvider`       |
| SQL Server 2017               | `Microsoft.Data.Tools.Schema.Sql.Sql140DatabaseSchemaProvider`       |
| SQL Server 2019               | `Microsoft.Data.Tools.Schema.Sql.Sql150DatabaseSchemaProvider`       |
| SQL Server 2022               | `Microsoft.Data.Tools.Schema.Sql.Sql160DatabaseSchemaProvider`       |
| SQL Server 2025               | `Microsoft.Data.Tools.Schema.Sql.Sql170DatabaseSchemaProvider`       |
| Azure SQL Database            | `Microsoft.Data.Tools.Schema.Sql.SqlAzureV12DatabaseSchemaProvider`  |
| Azure Synapse SQL Pool        | `Microsoft.Data.Tools.Schema.Sql.SqlDwDatabaseSchemaProvider`        |
| Azure Synapse Serverless Pool | `Microsoft.Data.Tools.Schema.Sql.SqlServerlessDatabaseSchemaProvider`|
| Fabric Data Warehouse         | `Microsoft.Data.Tools.Schema.Sql.SqlDwUnifiedDatabaseSchemaProvider` |
| SQL database in Fabric        | `Microsoft.Data.Tools.Schema.Sql.SqlDbFabricDatabaseSchemaProvider`  |

### 4. Update the .sln (if applicable)

Change the `ProjectTypeGuid` for the SQL project entry to:

    ```text
    {42EA0DBD-9CF1-443E-919E-BE9C484E4577}
    ```

### 5. Build and verify

    ```bash
    dotnet build YourProject.sqlproj

    # Compare against the original dacpac
    DacpacVerify original.dacpac bin/Debug/net8.0/YourProject.dacpac
    ```

If DacpacVerify reports differences, investigate — likely a missing pre/post-deploy
script or a refactorlog file that needs to be included.

### 6. Pre/post-deploy script gotchas

- Only **one** `<PreDeploy>` and **one** `<PostDeploy>` per project (same as legacy).
- Use `:r .\path\to\script.sql` (SQLCMD syntax) inside those entry-point scripts
  to include additional files.
- Files pulled in via `:r` must be **excluded from the build** with `<Build Remove="..." />`
  or they will be compiled as database objects and produce errors.
- Add them back as `<None Include="..." />` to keep them visible in the IDE.

### 7. Known limitations

- **SQLCLR:** Supported but requires .NET Framework + `msbuild` (not `dotnet build`).
  If you have SQLCLR objects, keep them in a separate project built with msbuild and
  reference the resulting dacpac as a package.

### 8. IDE and tooling impact — read before committing to the migration

This is a one-way conversion. Once converted, the project **cannot be reopened** in
classic SSDT. Understand the tooling landscape before proceeding.

**Visual Studio 2026** does not support SDK-style SQL projects at all. Only classic
SSDT is available in VS 2026. Microsoft states SDK-style support in VS 2026 is
"not yet on the roadmap, but actively under review" (DacFx wiki).

**Visual Studio 2022** has an SDK-style SSDT preview workload ("SQL Server Data Tools,
SDK-style (preview)"), but it is **still in preview** as of March 2026 and has
significant feature gaps compared to classic SSDT:

| Feature                         | Classic SSDT (VS 2022/2026) | SDK-style SSDT preview (VS 2022) | VS Code  |
| ------------------------------- | --------------------------- | -------------------------------- | -------- |
| Open SDK-style projects         | No                          | Yes                              | Yes      |
| Open classic projects           | Yes                         | No                               | Yes      |
| Schema compare (project to DB)  | Yes                         | Yes                              | Yes      |
| Schema compare (DB to project)  | Yes                         | **No**                           | Yes      |
| Graphical table designer        | Yes                         | Yes                              | No       |
| Code analysis                   | Yes                         | **No**                           | Yes      |
| IntelliSense from project model | Yes                         | **No**                           | No       |
| Object renaming / refactoring   | Yes                         | **No**                           | No       |
| Database settings GUI           | Yes                         | **No**                           | No       |
| Package references (NuGet)      | No                          | **No**                           | Yes      |
| Publish                         | Yes                         | Yes                              | Yes      |

**VS Code with the SQL Database Projects extension** is the most feature-complete
graphical tool for SDK-style projects. It supports schema compare, code analysis,
package references, and publishing. This is where Microsoft is investing most heavily.

**SSMS** is getting SDK-style SQL project support ("Database DevOps" workload).
Public preview for SQL projects and schema compare is planned for Q2 CY2026.

**Bottom line:** If your team relies on VS IntelliSense, refactoring, or DB-to-project
schema compare, those features do not yet exist in the SDK-style tooling. Evaluate
whether VS Code covers your workflow before migrating. The `dotnet build` / CI
benefits are real, but the IDE story is still catching up.

## References

- [Convert an original SQL project to SDK-style](https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/howto/convert-original-sql-project)
- [SDK-style SQL database projects overview](https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/sql-database-projects)
- [Target platform / DSP values](https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/concepts/target-platform)
- [Database references](https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/concepts/database-references)
- [Pre/post-deployment scripts](https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/concepts/pre-post-deployment-scripts)
- [GA announcement blog post](https://techcommunity.microsoft.com/blog/azuresqlblog/the-microsoft-build-sql-project-sdk-is-now-generally-available/4392063)
- [GitHub: microsoft/DacFx](https://github.com/microsoft/DacFx)
- [NuGet: Microsoft.Build.Sql](https://www.nuget.org/packages/Microsoft.Build.Sql)
