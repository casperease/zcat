<#
.SYNOPSIS
    Removes a manually installed Python and cleans up system PATH.
.DESCRIPTION
    Deletes the Python installation folder and removes it (and its Scripts
    subdirectory) from the system-level PATH. Requires Administrator.
    Auto-detects the install directory from Get-Command if not specified.

    This is for Python installations that do not appear in Apps & Features
    or winget. If Python is managed by winget, use Uninstall-Python instead.
.PARAMETER InstallDir
    Path to the Python installation folder. Auto-detected from PATH if omitted.
.PARAMETER Force
    Actually perform the removal. Without this, shows what would be removed.
.EXAMPLE
    Remove-Python
.EXAMPLE
    Remove-Python -Force
.EXAMPLE
    Remove-Python -InstallDir 'C:\Python312' -Force
#>
function Remove-Python {
    [CmdletBinding()]
    param(
        [string] $InstallDir,
        [switch] $Force
    )

    Assert-IsAdministrator

    $config = Get-ToolConfig -Tool 'Python'

    # Gate: if managed by our tooling system, refuse and redirect
    if (Test-ExpectedPackageManager -Config $config) {
        throw "Python is managed by the tooling system. Use Uninstall-Python instead."
    }

    # Auto-detect install directory
    if (-not $InstallDir) {
        $cmd = Get-Command $config.Command -ErrorAction SilentlyContinue
        if ($cmd) {
            $InstallDir = Split-Path $cmd.Source
        }
        else {
            $InstallDir = 'C:\Program Files\Python311'
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
    $pathChanged = Remove-SystemInstallation -InstallDir $resolvedDir -ExtraPathDirs 'Scripts'
    Write-Message "Deleted: $resolvedDir"
    if ($pathChanged) { Write-Message 'Removed from system PATH' }
    Write-Message 'Restart your terminal for PATH changes to take effect'
}
