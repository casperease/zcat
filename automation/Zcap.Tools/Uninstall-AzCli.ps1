<#
.SYNOPSIS
    Uninstalls the Azure CLI.
.DESCRIPTION
    macOS: Uninstalls via Homebrew.
    Windows/Linux: Uninstalls via pip.
    Idempotent — skips if not installed.
.PARAMETER Version
    Azure CLI version to uninstall. Defaults to the locked version in Get-ToolConfig.
.EXAMPLE
    Uninstall-AzCli
.EXAMPLE
    Uninstall-AzCli -Version '2.74'
#>
function Uninstall-AzCli {
    [CmdletBinding()]
    param(
        [string] $Version
    )

    # macOS: brew-managed, delegate to Uninstall-Tool
    if ($IsMacOS) {
        Uninstall-Tool -Tool 'AzCli' -Version $Version
        return
    }

    # Windows / Linux: pip-managed
    $config = Get-ToolConfig -Tool 'AzCli'

    # Idempotent: skip if not installed
    if (-not (Test-Command $config.Command)) {
        Write-Message "AzCli is not installed — nothing to do"
        return
    }

    Invoke-Pip "uninstall $($config.PipPackage) -y"
    Write-Message "AzCli uninstalled"
}
