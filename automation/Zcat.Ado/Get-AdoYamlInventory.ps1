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

    # ADO YamlPaths are relative to the repo root, but RelativePaths are
    # relative to the scan root. When scanning a subdirectory (e.g.,
    # -Path ..\infra\azure-pipelines), there is a prefix mismatch.
    # Detect it from the data: find a local file whose RelativePath is a
    # suffix of an ADO YamlPath and extract the prefix.
    $pathPrefix = ''
    foreach ($f in $files) {
        foreach ($d in $definitions) {
            if ($d.YamlPath -and $d.YamlPath.EndsWith("/$($f.RelativePath)")) {
                $pathPrefix = $d.YamlPath.Substring(0, $d.YamlPath.Length - $f.RelativePath.Length)
                break
            }
        }
        if ($pathPrefix) { break }
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
