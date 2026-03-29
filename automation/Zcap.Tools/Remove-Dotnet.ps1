<#
.SYNOPSIS
    Removes a system-installed .NET SDK and cleans up PATH and DOTNET_ROOT.
.DESCRIPTION
    Deletes the .NET SDK installation folder, removes it from the system-level
    PATH, and clears the system-level DOTNET_ROOT environment variable.
    Requires Administrator. Auto-detects the install directory from
    Get-Command if not specified.

    This is for system-wide .NET installations (standalone installer, Visual
    Studio side-installs). For user-scope script-installed .NET, use
    Uninstall-Dotnet instead.
.PARAMETER InstallDir
    Path to the .NET installation folder. Auto-detected from PATH if omitted.
.PARAMETER Force
    Actually perform the removal. Without this, shows what would be removed.
.EXAMPLE
    Remove-Dotnet
.EXAMPLE
    Remove-Dotnet -Force
#>
function Remove-Dotnet {
    [CmdletBinding()]
    param(
        [string] $InstallDir,
        [switch] $Force
    )

    Assert-IsAdministrator

    $config = Get-ToolConfig -Tool 'Dotnet'

    # Gate: if managed by our tooling system (script-installed to LOCALAPPDATA), refuse and redirect
    if (Test-ExpectedPackageManager -Config $config) {
        throw "Dotnet is managed by the tooling system. Use Uninstall-Dotnet instead."
    }

    # Auto-detect install directory
    if (-not $InstallDir) {
        $cmd = Get-Command $config.Command -ErrorAction SilentlyContinue
        if ($cmd) {
            $InstallDir = Split-Path $cmd.Source
        }
        else {
            $InstallDir = 'C:\Program Files\dotnet'
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
    $pathChanged = Remove-SystemInstallation -InstallDir $resolvedDir -EnvironmentVariables 'DOTNET_ROOT'
    Write-Message "Deleted: $resolvedDir"
    if ($pathChanged) { Write-Message 'Removed from system PATH' }
    Write-Message 'Restart your terminal for PATH changes to take effect'
}
