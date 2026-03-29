<#
.SYNOPSIS
    Removes an MSI-installed Azure CLI and cleans up system PATH.
.DESCRIPTION
    Deletes the Azure CLI installation folder and removes it from the
    system-level PATH. Requires Administrator. Auto-detects the install
    directory from Get-Command if not specified.

    This is for Azure CLI MSI installations. If Azure CLI is managed via
    pip by the tooling system, use Uninstall-AzCli instead.
.PARAMETER InstallDir
    Path to the Azure CLI installation folder. Auto-detected from PATH if omitted.
.PARAMETER Force
    Actually perform the removal. Without this, shows what would be removed.
.EXAMPLE
    Remove-AzCli
.EXAMPLE
    Remove-AzCli -Force
.EXAMPLE
    Remove-AzCli -InstallDir 'C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2' -Force
#>
function Remove-AzCli {
    [CmdletBinding()]
    param(
        [string] $InstallDir,
        [switch] $Force
    )

    Assert-IsAdministrator

    $config = Get-ToolConfig -Tool 'AzCli'

    # Gate: if managed by our tooling system (pip/brew), refuse and redirect
    if (Test-ExpectedPackageManager -Config $config) {
        throw "Azure CLI is managed by the tooling system. Use Uninstall-AzCli instead."
    }

    # Auto-detect install directory
    if (-not $InstallDir) {
        $cmd = Get-Command $config.Command -ErrorAction SilentlyContinue
        if ($cmd) {
            $binDir = Split-Path $cmd.Source
            # az.cmd lives in the wbin/ subdirectory of the MSI install
            $InstallDir = if ((Split-Path $binDir -Leaf) -eq 'wbin') { Split-Path $binDir } else { $binDir }
        }
        else {
            $InstallDir = 'C:\Program Files\Microsoft SDKs\Azure\CLI2'
        }
    }

    $resolvedDir = [System.IO.Path]::GetFullPath($InstallDir)

    if (-not [System.IO.Directory]::Exists($resolvedDir)) {
        Write-Message "Directory not found: $resolvedDir — nothing to remove"
        return
    }

    if (-not $Force) {
        Write-Message "Would remove: $resolvedDir"
        Write-Message 'Run with -Force to execute'
        return
    }

    Write-Message "Removing: $resolvedDir"
    $pathChanged = Remove-SystemInstallation -InstallDir $resolvedDir -ExtraPathDirs 'wbin'
    Write-Message "Deleted: $resolvedDir"
    if ($pathChanged) { Write-Message 'Removed from system PATH' }
    Write-Message 'Restart your terminal for PATH changes to take effect'
}
