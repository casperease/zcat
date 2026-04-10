# Zcat.Ado

Azure DevOps integration — REST API wrappers, pipeline utilities, and YAML file scanning.

## Authentication

All API functions use `Get-AdoAuthorizationHeader`, which tries three sources in order:

1. **Pipeline token** — `$env:SYSTEM_ACCESSTOKEN` (mapped in the step template).
2. **PAT** — `$env:AZURE_DEVOPS_PAT`.
3. **az CLI** — interactive login via `az account get-access-token`.

No configuration needed in pipelines. Locally, `az login` is sufficient.

## Configuration

Organization and project defaults live in `assets/config/ado.yml`. All API functions accept `-Organization` and `-Project` overrides, but default to the config values.

## YAML file scanning

For mono repos with a mix of ADO pipelines and templates, two functions work together to give a full picture.

### Scanning the filesystem

`Get-AdoYamlFiles` recursively finds `.yml`/`.yaml` files and classifies each as **Pipeline**, **Template**, or **Unknown** based on top-level YAML keys.

```powershell
# Scan the current repo
Get-AdoYamlFiles

# Scan a different repo
Get-AdoYamlFiles -Path 'C:\repos\big-mono'

# Custom directory exclusions (defaults: .git, node_modules, .terraform)
Get-AdoYamlFiles -Path 'C:\repos\big-mono' -Exclude @('.git', 'node_modules', 'vendor')
```

Each result includes:

| Property | Description |
|---|---|
| `Path` | Absolute file path |
| `RelativePath` | Repo-relative path (forward slashes) |
| `Directory` | Parent folder relative path |
| `Classification` | `Pipeline`, `Template`, or `Unknown` |
| `TemplateType` | `Stages`, `Jobs`, `Steps`, `Variables`, or `$null` |
| `TopLevelKeys` | Root YAML keys (useful for debugging `Unknown` files) |
| `ParseError` | Error message if YAML parsing failed, `$null` otherwise |

Templates are sub-classified by their body key — a file with `parameters:` + `steps:` gets `TemplateType = 'Steps'`.

### Querying registered pipelines

`Get-AdoPipelineDefinitions` lists all pipeline definitions registered in the ADO project via the Build Definitions API.

```powershell
# List all registered pipelines
Get-AdoPipelineDefinitions

# Filter to a specific repo
Get-AdoPipelineDefinitions | Where-Object RepositoryName -eq 'big-mono'
```

Each result includes:

| Property | Description |
|---|---|
| `Id` | Pipeline definition ID |
| `Name` | Display name in ADO |
| `Folder` | ADO folder path |
| `YamlPath` | Repo-relative YAML path (matches `RelativePath` from scan) |
| `FileName` | YAML file name |
| `RepositoryName` | Source repository name |
| `Revision` | Definition revision |
| `Url` | ADO web URL |

### Cross-referencing scan results with registered pipelines

The two functions compose naturally — `YamlPath` from the API matches `RelativePath` from the scan.

```powershell
$files = Get-AdoYamlFiles -Path 'C:\repos\big-mono'
$registered = Get-AdoPipelineDefinitions

# Pipeline files not registered in ADO
$files |
    Where-Object Classification -eq 'Pipeline' |
    Where-Object { $_.RelativePath -notin $registered.YamlPath }

# Group by directory to see distribution
$files | Group-Object Directory | ForEach-Object {
    [PSCustomObject]@{
        Directory = $_.Name
        Pipelines = ($_.Group | Where-Object Classification -eq 'Pipeline').Count
        Templates = ($_.Group | Where-Object Classification -eq 'Template').Count
        Unknown   = ($_.Group | Where-Object Classification -eq 'Unknown').Count
    }
}
```

## Pipeline utilities

`Set-AdoPipelineVariable` sets output variables with name sanitization and secret handling. `Register-AdoPipeline` creates a pipeline definition pointing to a YAML file. `Invoke-AdoRestMethod` is the general-purpose REST wrapper used by all API functions.
