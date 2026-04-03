<#
.SYNOPSIS
    Installs Node.js via the platform package manager.
.DESCRIPTION
    Installs Node.js LTS, which includes npm. Uses winget on Windows,
    brew on macOS, and apt-get on Linux. Idempotent — skips if already
    installed at the correct version.

    NOT for CI pipelines. In Azure DevOps, use the native UseNode task
    which activates pre-cached versions instantly:

        - task: UseNode@1
          inputs:
            version: '22.x'
.PARAMETER Version
    Node.js major version to install. Defaults to the locked version in Get-ToolConfig.
.PARAMETER Force
    Replace an existing installation at the wrong version.
.EXAMPLE
    Install-NodeJs
.EXAMPLE
    Install-NodeJs -Force
#>
function Install-NodeJs {
    [CmdletBinding()]
    param(
        [string] $Version,
        [switch] $Force
    )

    Assert-False (Test-IsRunningInPipeline) -ErrorText (
        "Install-NodeJs is for developer workstations, not CI. " +
        "In ADO pipelines, use the native task: - task: UseNode@1 inputs: version: '22.x'"
    )

    Install-Tool -Tool 'NodeJs' -Version $Version -Force:$Force
}
