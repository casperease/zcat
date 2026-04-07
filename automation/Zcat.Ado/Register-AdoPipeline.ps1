<#
.SYNOPSIS
    Creates an Azure DevOps pipeline pointing to a YAML file.
.DESCRIPTION
    Uses the ADO Pipelines REST API to register a pipeline definition backed
    by a YAML file. Supports both Azure Repos Git and GitHub repositories.
    Throws if a pipeline with the same name already exists.

    Requires authentication via Get-AdoAuthorizationHeader (pipeline token or az login).
.PARAMETER Name
    Display name for the pipeline in Azure DevOps.
.PARAMETER YamlPath
    Repository-relative path to the YAML file (e.g. 'pipelines/ci.yaml').
.PARAMETER GitHubRepository
    Full GitHub repository URL (e.g. 'https://github.com/owner/repo').
    When set, the pipeline sources from GitHub instead of Azure Repos Git.
    Requires a GitHub service connection in the ADO project.
.PARAMETER ConnectionId
    ID of the GitHub service connection in ADO. Required when using -GitHubRepository.
.PARAMETER Project
    Azure DevOps project name. Defaults to the value in ado.yml.
.PARAMETER Organization
    Azure DevOps organization URL. Defaults to the value in ado.yml.
.PARAMETER RepositoryName
    Name of the Azure Repos Git repository. Ignored when -GitHubRepository is set.
    Defaults to $env:BUILD_REPOSITORY_NAME or the leaf folder of $env:RepositoryRoot.
.PARAMETER FolderPath
    Pipeline folder path in ADO. Defaults to root ('\').
.EXAMPLE
    Register-AdoPipeline 'CI' 'pipelines/ci.yaml'
.EXAMPLE
    Register-AdoPipeline 'CI' 'pipelines/ci.yaml' -GitHubRepository 'https://github.com/casperease/zcat' -ConnectionId $id
.EXAMPLE
    Register-AdoPipeline 'CI Expected Failures' 'pipelines/ci-expected-failures.yaml' -FolderPath '\CI'
#>
function Register-AdoPipeline {
    [CmdletBinding(DefaultParameterSetName = 'AzureRepos')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Name,

        [Parameter(Mandatory, Position = 1)]
        [string] $YamlPath,

        [Parameter(ParameterSetName = 'GitHub', Mandatory)]
        [string] $GitHubRepository,

        [Parameter(ParameterSetName = 'GitHub', Mandatory)]
        [string] $ConnectionId,

        [string] $Project,

        [string] $Organization,

        [Parameter(ParameterSetName = 'AzureRepos')]
        [string] $RepositoryName,

        [string] $FolderPath = '\'
    )

    $adoConfig = Get-AdoConfig
    if (-not $Project) { $Project = $adoConfig['Project'] }
    if (-not $Organization) { $Organization = $adoConfig['Organization'] }

    Assert-NotNullOrWhitespace $Project -ErrorText 'Project is required. Set -Project or configure ado.yml.'
    Assert-NotNullOrWhitespace $Organization -ErrorText 'Organization is required. Set -Organization or configure ado.yml.'
    $Organization = $Organization.TrimEnd('/')

    $apiBase = "$Organization/$Project/_apis"

    # Check if pipeline already exists
    $existing = Invoke-AdoRestMethod -Uri "$apiBase/pipelines?api-version=7.1-preview.1"
    $found = $existing | Where-Object { $_.name -eq $Name } | Select-Object -First 1

    if ($found) {
        throw "Pipeline '$Name' already exists (id: $($found.id)). Use the ADO portal to update it."
    }

    # Build repository config based on source type
    if ($PSCmdlet.ParameterSetName -eq 'GitHub') {
        $repoFullName = $GitHubRepository -replace '^https://github\.com/', ''

        # Resolve connection name to GUID if needed
        if (-not [guid]::TryParse($ConnectionId, [ref][guid]::Empty)) {
            $endpoints = Invoke-AdoRestMethod -Uri "$apiBase/serviceendpoint/endpoints?endpointNames=$ConnectionId&api-version=7.1-preview.4"
            $endpoint = $endpoints | Select-Object -First 1
            Assert-NotNull $endpoint -ErrorText "Service connection '$ConnectionId' not found in organization '$Organization'"
            $ConnectionId = $endpoint.id
        }

        $repoConfig = @{
            fullName   = $repoFullName
            type       = 'gitHub'
            connection = @{
                id = $ConnectionId
            }
        }
    }
    else {
        if (-not $RepositoryName) {
            $RepositoryName = if ($env:BUILD_REPOSITORY_NAME) {
                $env:BUILD_REPOSITORY_NAME
            }
            else {
                Split-Path $env:RepositoryRoot -Leaf
            }
            Assert-NotNullOrWhitespace $RepositoryName -ErrorText 'RepositoryName is required. Set -RepositoryName, or ensure $env:BUILD_REPOSITORY_NAME or $env:RepositoryRoot is set.'
        }

        $repos = Invoke-AdoRestMethod -Uri "$apiBase/git/repositories?api-version=7.1"
        $repo = $repos | Where-Object { $_.name -eq $RepositoryName } | Select-Object -First 1
        Assert-NotNull $repo -ErrorText "Repository '$RepositoryName' not found in project '$Project'"

        $repoConfig = @{
            id   = $repo.id
            type = 'azureReposGit'
        }
    }

    # Create pipeline
    $body = @{
        name          = $Name
        folder        = $FolderPath
        configuration = @{
            type       = 'yaml'
            path       = "/$YamlPath"
            repository = $repoConfig
        }
    }

    $result = Invoke-AdoRestMethod -Uri "$apiBase/pipelines?api-version=7.1-preview.1" -Method Post -Body $body
    Write-Message "Created pipeline '$Name' (id: $($result.id)) -> $YamlPath"
    $result
}
