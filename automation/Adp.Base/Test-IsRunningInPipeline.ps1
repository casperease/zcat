<#
.SYNOPSIS
    Returns true if the current session is running inside a CI/CD pipeline.
.DESCRIPTION
    Detects Azure DevOps Pipelines and GitHub Actions by checking for
    environment variables set by each platform's agent.
.EXAMPLE
    Test-IsRunningInPipeline
.EXAMPLE
    if (Test-IsRunningInPipeline) { Write-Verbose 'Running in CI' }
#>
function Test-IsRunningInPipeline {
    [OutputType([bool])]
    [CmdletBinding()]
    param()

    # Azure DevOps sets TF_BUILD=True
    # GitHub Actions sets GITHUB_ACTIONS=true
    [bool]$env:TF_BUILD -or [bool]$env:GITHUB_ACTIONS
}
