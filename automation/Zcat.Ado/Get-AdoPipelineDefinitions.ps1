<#
.SYNOPSIS
    Lists all registered pipeline definitions from Azure DevOps.
.DESCRIPTION
    Queries the ADO Build Definitions REST API and returns a flattened
    list of pipeline definitions with their YAML paths, repository names,
    and ADO folder placement.

    YamlPath is normalized (leading '/' stripped) to match the RelativePath
    output of Get-AdoYamlFiles for easy cross-referencing.
.PARAMETER Project
    Azure DevOps project name. Defaults to the value in ado.yml.
.PARAMETER Organization
    Azure DevOps organization URL. Defaults to the value in ado.yml.
.EXAMPLE
    Get-AdoPipelineDefinitions
.EXAMPLE
    Get-AdoPipelineDefinitions -Organization 'https://dev.azure.com/myorg' -Project 'myproject'
.EXAMPLE
    Get-AdoPipelineDefinitions | Where-Object RepositoryName -eq 'big-mono'
#>
function Get-AdoPipelineDefinitions {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [string] $Project,

        [string] $Organization
    )

    $adoConfig = Get-AdoConfig
    if (-not $Project) { $Project = $adoConfig['Project'] }
    if (-not $Organization) { $Organization = $adoConfig['Organization'] }

    Assert-NotNullOrWhitespace $Project -ErrorText 'Project is required. Set -Project or configure ado.yml.'
    Assert-NotNullOrWhitespace $Organization -ErrorText 'Organization is required. Set -Organization or configure ado.yml.'
    $Organization = $Organization.TrimEnd('/')

    $apiBase = "$Organization/$Project/_apis"

    Write-Message "Listing pipeline definitions from: $Organization/$Project"

    $definitions = Invoke-AdoRestMethod -Uri "$apiBase/build/definitions?api-version=7.1&includeAllProperties=true&`$top=10000"
    Assert-NotNull $definitions -ErrorText 'Build Definitions API returned null'

    $count = ($definitions | Measure-Object).Count
    Write-Message "Found $count pipeline definitions"

    foreach ($d in $definitions) {
        $yamlPath = $d.process.yamlFilename
        if ($yamlPath) {
            $yamlPath = $yamlPath.TrimStart('/').TrimStart('.\') -replace '\\', '/'
        }

        $fileName = if ($yamlPath) { Split-Path $yamlPath -Leaf } else { $null }
        $repoName = $d.repository.properties.shortName ?? $d.repository.name

        [PSCustomObject]@{
            Id             = $d.id
            Name           = $d.name
            Folder         = $d.path
            YamlPath       = $yamlPath
            FileName       = $fileName
            RepositoryName = $repoName
            Revision       = $d.revision
            Url            = $d._links.web.href
        }
    }
}
