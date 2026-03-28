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

    # Windows / Linux: pip-based install (same pattern as Install-Poetry)
    $config = Get-ToolConfig -Tool 'AzCli'
    if (-not $Version) { $Version = $config.Version }

    # Idempotent: skip if already installed at the correct version
    if (Test-Command $config.Command) {
        $raw = Invoke-CliCommand $config.VersionCommand -PassThru -NoAssert -Silent
        if ($raw -match $config.VersionPattern -and $Matches['ver'].StartsWith($Version)) {
            Write-Message "AzCli $Version is already installed"
            return
        }

        $installed = $Matches['ver']
        $location = (Get-Command $config.Command).Source

        if ($Force) {
            Write-Verbose "AzCli $installed found at '$location' — uninstalling before installing $Version"
            Invoke-Pip "uninstall $($config.PipPackage) -y"
        }
        else {
            throw "AzCli version mismatch: expected $Version.x, found $installed at '$location'. Run Install-AzCli -Force to replace, or uninstall manually."
        }
    }

    Invoke-Pip "install $($config.PipPackage)==$Version.*"

    Assert-Command $config.Command -ErrorText "AzCli was installed but '$($config.Command)' is not on PATH. You may need to restart your shell."
    Write-Message "AzCli $Version installed successfully"
}
