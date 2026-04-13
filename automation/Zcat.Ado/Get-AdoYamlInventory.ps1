<#
.SYNOPSIS
    Combines YAML file scanning with ADO pipeline registration data.
.DESCRIPTION
    Runs Get-AdoYamlFiles to classify files by heuristics, then
    Get-AdoPipelineDefinitions to fetch registered pipelines from ADO.
    Cross-references the two datasets to:

    - Mark each file as registered or not.
    - Resolve Unknown classifications: if a file is registered as a
      pipeline in ADO, it is reclassified as Pipeline.
    - Attach the ADO pipeline name and ID to registered files.
.PARAMETER Path
    Root directory to scan. Defaults to the repository root via Get-RepositoryRoot.
.PARAMETER Exclude
    Directory names to skip during scanning. Matched as exact names anywhere in the path.
    Defaults to @('.git', 'node_modules', '.terraform').
.PARAMETER Project
    Azure DevOps project name. Defaults to the value in ado.yml.
.PARAMETER Organization
    Azure DevOps organization URL. Defaults to the value in ado.yml.
.EXAMPLE
    Get-AdoYamlInventory -Path 'C:\repos\big-mono'
.EXAMPLE
    Get-AdoYamlInventory -Path 'C:\repos\big-mono' | Where-Object { -not $_.IsRegistered -and $_.Classification -eq 'Pipeline' }
#>
function Get-AdoYamlInventory {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [string] $Path,

        [string[]] $Exclude = @('.git', 'node_modules', '.terraform'),

        [string] $Project,

        [string] $Organization
    )

    $scanParams = @{ Exclude = $Exclude }
    if ($Path) { $scanParams.Path = $Path }

    $files = Get-AdoYamlFiles @scanParams

    # Compute the path prefix between the git root and the scan root.
    # ADO YamlPaths are relative to the repo root, but Get-AdoYamlFiles
    # returns RelativePaths relative to the scan root. When the scan root
    # is a subdirectory (e.g., -Path ..\infra\azure-pipelines), we need
    # to prepend the offset so paths align for cross-referencing.
    $scanRoot = if ($Path) { (Resolve-Path $Path).Path } else { Get-RepositoryRoot }
    $pathPrefix = ''
    $gitRoot = Invoke-Executable "git -C ""$scanRoot"" rev-parse --show-toplevel" -PassThru -NoAssert -Silent
    if ($gitRoot.ExitCode -eq 0 -and $gitRoot.Output) {
        $resolvedGitRoot = (Resolve-Path $gitRoot.Output.Trim()).Path
        if ($scanRoot -ne $resolvedGitRoot) {
            $pathPrefix = $scanRoot.Substring($resolvedGitRoot.Length).TrimStart([IO.Path]::DirectorySeparatorChar, '/') -replace '\\', '/'
            if ($pathPrefix) { $pathPrefix += '/' }
        }
    }

    $defParams = @{}
    if ($Project) { $defParams.Project = $Project }
    if ($Organization) { $defParams.Organization = $Organization }

    $definitions = Get-AdoPipelineDefinitions @defParams

    $registeredByPath = @{}
    foreach ($d in $definitions) {
        if ($d.YamlPath) {
            $registeredByPath[$d.YamlPath] = $d
        }
    }

    foreach ($file in $files) {
        $registered = $registeredByPath[$pathPrefix + $file.RelativePath]
        $isRegistered = $null -ne $registered

        $classification = $file.Classification
        if ($classification -eq 'Unknown' -and $isRegistered) {
            $classification = 'Pipeline'
        }

        [PSCustomObject]@{
            Path           = $file.Path
            RelativePath   = $file.RelativePath
            Directory      = $file.Directory
            Classification = $classification
            TemplateType   = $file.TemplateType
            IsRegistered   = $isRegistered
            PipelineName   = $registered.Name
            PipelineId     = $registered.Id
            TopLevelKeys   = $file.TopLevelKeys
            ParseError     = $file.ParseError
        }
    }
}
