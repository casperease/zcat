<#
.SYNOPSIS
    Installs Git (user-space on Windows, package manager elsewhere).
.DESCRIPTION
    Windows: Downloads the latest PortableGit from git-scm.com (GitHub
    releases) and extracts to LOCALAPPDATA\Git. No admin required.
    Persists PATH for future sessions.
    macOS: brew install git.
    Linux: apt-get install git (requires root).
    Idempotent — skips if already installed.
.PARAMETER Force
    Remove an existing installation before reinstalling.
.EXAMPLE
    Install-Git
.EXAMPLE
    Install-Git -Force
#>
function Install-Git {
    [CmdletBinding()]
    param(
        [switch] $Force
    )

    if ($IsWindows) {
        $installDir = Join-Path $env:LOCALAPPDATA 'Git'
        $cmdDir = Join-Path $installDir 'cmd'
        $gitBinary = Join-Path $cmdDir 'git.exe'

        if ((Test-Path $gitBinary) -and -not $Force) {
            Write-Message "Git is already installed at '$installDir'"
            return
        }

        if ($Force -and (Test-Path $installDir)) {
            Write-Verbose "Removing existing installation at '$installDir'"
            Uninstall-Git
        }

        # Get the latest release from Git for Windows
        Write-Message 'Resolving latest Git for Windows release'
        $releasesUrl = 'https://api.github.com/repos/git-for-windows/git/releases/latest'
        $release = Invoke-RestMethod -Uri $releasesUrl -Headers @{ Accept = 'application/vnd.github+json' }
        Assert-NotNull $release -ErrorText 'Could not fetch latest Git for Windows release from GitHub'

        # Find the PortableGit 64-bit self-extracting archive
        $asset = $release.assets | Where-Object { $_.name -match '^PortableGit-.*-64-bit\.7z\.exe$' }
        Assert-NotNull $asset -ErrorText "No PortableGit 64-bit archive found in release $($release.tag_name)"
        $downloadUrl = $asset.browser_download_url

        $exePath = Join-Path ([IO.Path]::GetTempPath()) $asset.name

        Write-Message "Downloading $($asset.name)"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath -UseBasicParsing
        Assert-PathExist $exePath

        # PortableGit .7z.exe is a self-extracting archive. The -o flag sets
        # the output directory and -y suppresses prompts.
        Write-Message "Extracting to '$installDir'"
        Invoke-Executable "$exePath -o`"$installDir`" -y"
        Remove-Item $exePath -Force

        Assert-PathExist $cmdDir

        Add-PermanentPath $cmdDir -Prepend

        Assert-Command git -ErrorText "Git was installed but 'git' is not on PATH. You may need to restart your shell."
        Write-Message "Git installed successfully to '$installDir'"
    }
    elseif ($IsMacOS) {
        Assert-Command brew
        if (Test-Command git) {
            if (-not $Force) {
                Write-Message 'Git is already installed'
                return
            }
            Invoke-Executable 'brew reinstall git'
        }
        else {
            Invoke-Executable 'brew install git'
        }
        Write-Message 'Git installed successfully via brew'
    }
    elseif ($IsLinux) {
        Assert-IsAdministrator -ErrorText 'Install-Git on Linux requires root (apt-get). Run as root or install Git manually.'
        Assert-Command apt-get
        Invoke-Executable 'sudo apt-get update -qq'
        Invoke-Executable 'sudo apt-get install -y git'
        Assert-Command git -ErrorText "Git was installed but 'git' is not on PATH."
        Write-Message 'Git installed successfully via apt-get'
    }
    else {
        throw 'Unsupported platform for Git installation'
    }
}
