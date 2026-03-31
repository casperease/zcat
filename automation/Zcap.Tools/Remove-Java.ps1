<#
.SYNOPSIS
    Removes a manually installed Java JDK and cleans up system PATH.
.DESCRIPTION
    Deletes the JDK installation folder and removes it (and its bin
    subdirectory) from the system-level PATH. Requires Administrator.
    Auto-detects the install directory from Get-Command if not specified.

    This is for JDK installations (Oracle, AdoptOpenJDK, etc.) that
    are not managed by winget/brew/apt. If Java is managed by the
    tooling system, use Uninstall-Java instead.
.PARAMETER InstallDir
    Path to the JDK installation folder. Auto-detected from PATH if omitted.
.PARAMETER Force
    Actually perform the removal. Without this, shows what would be removed.
.EXAMPLE
    Remove-Java
.EXAMPLE
    Remove-Java -Force
.EXAMPLE
    Remove-Java -InstallDir 'C:\Program Files\Java\jdk-17' -Force
#>
function Remove-Java {
    [CmdletBinding()]
    param(
        [string] $InstallDir,
        [switch] $Force
    )

    Assert-IsAdministrator

    $config = Get-ToolConfig -Tool 'Java'

    if (Test-ExpectedPackageManager -Config $config) {
        throw "Java is managed by the tooling system. Use Uninstall-Java instead."
    }

    if (-not $InstallDir) {
        $cmd = Get-Command $config.Command -ErrorAction SilentlyContinue
        if ($cmd) {
            # java.exe is typically in bin/ under the JDK root
            $InstallDir = Split-Path (Split-Path $cmd.Source)
        }
        else {
            $InstallDir = 'C:\Program Files\Java'
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
    $pathChanged = Remove-SystemInstallation -InstallDir $resolvedDir -ExtraPathDirs 'bin' -EnvironmentVariables 'JAVA_HOME'
    Write-Message "Deleted: $resolvedDir"
    if ($pathChanged) { Write-Message 'Removed from system PATH' }
    Write-Message 'Restart your terminal for PATH changes to take effect'
}
