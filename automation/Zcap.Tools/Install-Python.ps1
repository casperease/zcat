<#
.SYNOPSIS
    Installs Python via the platform package manager.
.DESCRIPTION
    Uses winget on Windows, brew on macOS, and apt-get on Linux.
    Idempotent — skips if already installed at the correct version.

    NOT for CI pipelines. In Azure DevOps, use the native UsePythonVersion task
    which activates pre-cached versions instantly:

        - task: UsePythonVersion@0
          inputs:
            versionSpec: '3.11'
.PARAMETER Version
    Python version to install. Defaults to the locked version in Get-ToolConfig.
.PARAMETER Force
    Replace an existing installation at the wrong version.
.EXAMPLE
    Install-Python
.EXAMPLE
    Install-Python -Version '3.12'
#>
function Install-Python {
    [CmdletBinding()]
    param(
        [string] $Version,
        [switch] $Force
    )

    Assert-False (Test-IsRunningInPipeline) -ErrorText (
        "Install-Python is for developer workstations, not CI. " +
        "In ADO pipelines, use the native task: - task: UsePythonVersion@0 inputs: versionSpec: '3.11'"
    )

    Install-Tool -Tool 'Python' -Version $Version -Force:$Force

    # Keep pip current — we only pin the Python version, not pip.
    # -q suppresses the dependency list; runs after Install-Tool so it
    # only fires when Python is actually present on PATH.
    if (Test-Command pip) {
        Invoke-CliCommand 'python -m pip install -q --upgrade pip'
    }
}
