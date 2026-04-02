<#
.SYNOPSIS
    Returns the path to the output directory for the current execution context.
.DESCRIPTION
    In an Azure DevOps pipeline, returns $env:BUILD_ARTIFACTSTAGINGDIRECTORY.
    Locally, returns {RepositoryRoot}/out.

    With -EnsureExists, creates the directory if it does not exist.
.PARAMETER EnsureExists
    Create the output directory if it does not exist.
.EXAMPLE
    $outDir = Get-OutputRoot
.EXAMPLE
    $outDir = Get-OutputRoot -EnsureExists
#>
function Get-OutputRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [switch] $EnsureExists
    )

    $outputPath = if ((Test-IsRunningInPipeline) -and $env:BUILD_ARTIFACTSTAGINGDIRECTORY) {
        Assert-PathExist $env:BUILD_ARTIFACTSTAGINGDIRECTORY -PathType Container
        $env:BUILD_ARTIFACTSTAGINGDIRECTORY
    }
    else {
        Join-Path (Get-RepositoryRoot) 'out'
    }

    if ($EnsureExists -and -not (Test-Path $outputPath -PathType Container)) {
        New-Item -Path $outputPath -ItemType Directory | Out-Null
    }

    $outputPath
}
