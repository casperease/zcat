<#
.SYNOPSIS
    Uninstalls Git installed by Install-Git.
.DESCRIPTION
    Windows: Removes LOCALAPPDATA\Git and cleans PATH.
    macOS: brew uninstall git.
    Linux: apt-get remove git (requires root).
    Idempotent — skips if not installed.
.EXAMPLE
    Uninstall-Git
#>
function Uninstall-Git {
    [CmdletBinding()]
    param()

    if ($IsWindows) {
        $installDir = Join-Path $env:LOCALAPPDATA 'Git'
        $cmdDir = Join-Path $installDir 'cmd'

        if (-not (Test-Path $installDir)) {
            Write-Message "Git is not installed at '$installDir' — nothing to do"
            return
        }

        Write-Message "Removing '$installDir'"
        Remove-Item $installDir -Recurse -Force

        Remove-PermanentPath $cmdDir

        Write-Message "Git uninstalled from '$installDir'"
    }
    elseif ($IsMacOS) {
        Assert-Command brew
        if (-not (Test-Command git)) {
            Write-Message 'Git is not installed — nothing to do'
            return
        }
        Invoke-CliCommand 'brew uninstall git'
        Write-Message 'Git uninstalled via brew'
    }
    elseif ($IsLinux) {
        Assert-IsAdministrator -ErrorText 'Uninstall-Git on Linux requires root (apt-get). Run as root or uninstall Git manually.'
        Assert-Command apt-get
        Invoke-CliCommand 'sudo apt-get remove -y git'
        Write-Message 'Git uninstalled via apt-get'
    }
    else {
        throw 'Unsupported platform for Git uninstallation'
    }
}
