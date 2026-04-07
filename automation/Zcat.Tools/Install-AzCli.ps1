<#
.SYNOPSIS
    Installs the Azure CLI.
.DESCRIPTION
    macOS: Installs via Homebrew (user-space).
    Windows/Linux: Installs via pip (user-space, no admin).
    Idempotent — skips if already installed at the correct version.
.PARAMETER Version
    Azure CLI version to install. Defaults to the locked version in Get-ToolConfig.
.PARAMETER Force
    Replace an existing installation at the wrong version.
.EXAMPLE
    Install-AzCli
.EXAMPLE
    Install-AzCli -Version '2.74'
#>
function Install-AzCli {
    [CmdletBinding()]
    param(
        [string] $Version,
        [switch] $Force
    )

    # macOS: brew is user-space, delegate to Install-Tool
    if ($IsMacOS) {
        Install-Tool -Tool 'AzCli' -Version $Version -Force:$Force
        return
    }

    # Windows / Linux: pip-based install
    Install-PipTool -Tool 'AzCli' -Version $Version -Force:$Force
}
