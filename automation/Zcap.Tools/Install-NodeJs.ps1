<#
.SYNOPSIS
    Installs Node.js via the platform package manager.
.DESCRIPTION
    Installs Node.js LTS, which includes npm. Uses winget on Windows,
    brew on macOS, and apt-get on Linux. Idempotent — skips if already
    installed at the correct version.
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

    Install-Tool -Tool 'NodeJs' -Version $Version -Force:$Force
}
