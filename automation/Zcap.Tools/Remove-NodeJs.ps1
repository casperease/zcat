<#
.SYNOPSIS
    Removes a manually installed Node.js and cleans up system PATH.
.DESCRIPTION
    Deletes the Node.js installation folder and removes it from the
    system-level PATH. Requires Administrator. Auto-detects the install
    directory from Get-Command if not specified.

    This is for Node.js installations that do not appear in Apps & Features
    or winget. If Node.js is managed by winget, use Uninstall-NodeJs instead.
.PARAMETER InstallDir
    Path to the Node.js installation folder. Auto-detected from PATH if omitted.
.PARAMETER Force
    Actually perform the removal. Without this, shows what would be removed.
.EXAMPLE
    Remove-NodeJs
.EXAMPLE
    Remove-NodeJs -Force
.EXAMPLE
    Remove-NodeJs -InstallDir 'D:\tools\nodejs' -Force
#>
function Remove-NodeJs {
    [CmdletBinding()]
    param(
        [string] $InstallDir,
        [switch] $Force
    )

    Assert-IsAdministrator

    $config = Get-ToolConfig -Tool 'NodeJs'

    # Gate: if managed by our tooling system, refuse and redirect
    if (Test-ExpectedPackageManager -Config $config) {
        throw "Node.js is managed by the tooling system. Use Uninstall-NodeJs instead."
    }

    # Auto-detect install directory
    if (-not $InstallDir) {
        $cmd = Get-Command $config.Command -ErrorAction SilentlyContinue
        if ($cmd) {
            $InstallDir = Split-Path $cmd.Source
        }
        else {
            $InstallDir = 'C:\Program Files\nodejs'
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
    $pathChanged = Remove-SystemInstallation -InstallDir $resolvedDir
    Write-Message "Deleted: $resolvedDir"
    if ($pathChanged) { Write-Message 'Removed from system PATH' }
    Write-Message 'Restart your terminal for PATH changes to take effect'
}
