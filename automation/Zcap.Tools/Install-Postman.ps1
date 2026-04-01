<#
.SYNOPSIS
    Installs the Postman desktop app (user-space, no admin required).
.DESCRIPTION
    Windows: Downloads the official installer from dl.pstmn.io and runs it
    silently. Installs to LOCALAPPDATA\Postman (Squirrel/Electron default).
    macOS: brew install --cask postman.
    Linux: Downloads the tar.gz from dl.pstmn.io and extracts to
    HOME/.local/Postman.
    Idempotent — skips if already installed.
.PARAMETER Force
    Remove an existing installation before reinstalling.
.EXAMPLE
    Install-Postman
.EXAMPLE
    Install-Postman -Force
#>
function Install-Postman {
    [CmdletBinding()]
    param(
        [switch] $Force
    )

    if ($IsWindows) {
        $installDir = Join-Path $env:LOCALAPPDATA 'Postman'
        $postmanExe = Join-Path $installDir 'Postman.exe'

        if ((Test-Path $postmanExe) -and -not $Force) {
            Write-Message "Postman is already installed at '$installDir'"
            return
        }

        if ($Force -and (Test-Path $installDir)) {
            Write-Verbose "Removing existing installation at '$installDir'"
            Uninstall-Postman
        }

        $setupPath = Join-Path ([IO.Path]::GetTempPath()) 'Postman-win64-setup.exe'

        Write-Message 'Downloading Postman from dl.pstmn.io'
        Invoke-WebRequest -Uri 'https://dl.pstmn.io/download/latest/win64' -OutFile $setupPath -UseBasicParsing
        Assert-PathExist $setupPath

        Write-Message "Installing Postman to '$installDir'"
        Invoke-CliCommand "$setupPath --silent"
        Remove-Item $setupPath -Force

        Assert-PathExist $postmanExe -ErrorText "Postman was installed but '$postmanExe' not found. The installer may have placed it elsewhere."
        Write-Message "Postman installed successfully to '$installDir'"
    }
    elseif ($IsMacOS) {
        Assert-Command brew

        if (& brew list --cask postman 2>$null) {
            if (-not $Force) {
                Write-Message 'Postman is already installed via brew'
                return
            }
            Write-Verbose 'Removing existing brew cask before reinstalling'
            Invoke-CliCommand 'brew uninstall --cask postman'
        }

        Invoke-CliCommand 'brew install --cask postman'
        Write-Message 'Postman installed successfully via brew'
    }
    elseif ($IsLinux) {
        $installDir = Join-Path $HOME '.local/Postman'
        $postmanBinary = Join-Path $installDir 'Postman'

        if ((Test-Path $postmanBinary) -and -not $Force) {
            Write-Message "Postman is already installed at '$installDir'"
            return
        }

        if ($Force -and (Test-Path $installDir)) {
            Write-Verbose "Removing existing installation at '$installDir'"
            Remove-Item $installDir -Recurse -Force
        }

        $tarPath = Join-Path ([IO.Path]::GetTempPath()) 'postman-linux-x64.tar.gz'

        Write-Message 'Downloading Postman from dl.pstmn.io'
        Invoke-WebRequest -Uri 'https://dl.pstmn.io/download/latest/linux_64' -OutFile $tarPath -UseBasicParsing
        Assert-PathExist $tarPath

        # The tar.gz extracts a Postman/ directory containing the app
        $extractDir = [IO.Path]::GetTempPath()
        Invoke-CliCommand "tar -xzf '$tarPath' -C '$extractDir'"
        Remove-Item $tarPath -Force

        $extracted = Join-Path $extractDir 'Postman'
        Assert-PathExist $extracted

        $parentDir = Split-Path $installDir
        if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
        Move-Item $extracted $installDir -Force

        Assert-PathExist $postmanBinary
        Write-Message "Postman installed successfully to '$installDir'"
    }
    else {
        throw 'Unsupported platform for Postman installation'
    }
}
