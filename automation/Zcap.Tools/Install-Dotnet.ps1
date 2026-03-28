<#
.SYNOPSIS
    Installs the .NET SDK via official Microsoft install scripts (user-space).
.DESCRIPTION
    Uses vendored dotnet-install scripts instead of package managers.
    Windows: installs to C:\tools\dotnet (avoids OneDrive-redirected $HOME).
    Unix: installs to ~/.dotnet.
    No admin required. Persists DOTNET_ROOT and PATH for future sessions.
    Idempotent — skips if already installed at the correct version.
    Dotnet supports side-by-side installs, so a system-wide dotnet (e.g.,
    from Visual Studio) does not conflict and is not blocked.
.PARAMETER Version
    .NET SDK version to install. Defaults to the locked version in Get-ToolConfig.
.PARAMETER Force
    Replace an existing installation at the wrong version.
.EXAMPLE
    Install-Dotnet
.EXAMPLE
    Install-Dotnet -Version '10.0'
#>
function Install-Dotnet {
    [CmdletBinding()]
    param(
        [string] $Version,
        [switch] $Force
    )

    $config = Get-ToolConfig -Tool 'Dotnet'
    if (-not $Version) { $Version = $config.Version }

    # Windows: C:\tools\dotnet — avoids OneDrive/DST-redirected $HOME.
    # Unix: ~/.dotnet — standard Microsoft convention.
    $installDir = if ($IsWindows -and $config.WindowsInstallRoot) {
        Join-Path $config.WindowsInstallRoot ($config.WindowsInstallDir ?? $config.UserInstallDir)
    } else {
        Join-Path $HOME $config.UserInstallDir
    }
    $ourBinary = if ($IsWindows) { Join-Path $installDir 'dotnet.exe' } else { Join-Path $installDir 'dotnet' }

    # Idempotent: check OUR install directory specifically, not the system PATH.
    # Dotnet supports side-by-side — a VS-installed or system dotnet at
    # C:\Program Files\dotnet\ is irrelevant; it doesn't block our install.
    if (Test-Path $ourBinary) {
        $raw = Invoke-CliCommand "$ourBinary --version" -PassThru -NoAssert -Silent
        if ($raw -match $config.VersionPattern -and $Matches['ver'].StartsWith($Version)) {
            Write-Message "Dotnet $Version is already installed at '$installDir'"
            return
        }

        $installed = $Matches['ver']

        if ($Force) {
            Write-Verbose "Dotnet $installed found at '$installDir' — reinstalling $Version"
        }
        else {
            throw "Dotnet version mismatch: expected $Version.x, found $installed at '$installDir'. Run Install-Dotnet -Force to replace."
        }
    }

    # Resolve vendored install script
    if ($IsWindows) {
        $scriptPath = Join-Path $PSScriptRoot 'scripts' 'dotnet-install.ps1'
        Assert-PathExist $scriptPath
        Write-Message "Installing .NET SDK $Version to '$installDir'"
        & $scriptPath -Channel $Version -InstallDir $installDir -Quality ga
    }
    else {
        $scriptPath = Join-Path $PSScriptRoot 'scripts' 'dotnet-install.sh'
        Assert-PathExist $scriptPath
        Write-Message "Installing .NET SDK $Version to '$installDir'"
        Invoke-CliCommand "bash '$scriptPath' --channel $Version --install-dir $installDir --quality ga"
    }

    # Set environment for current session
    $env:DOTNET_ROOT = $installDir
    $env:PATH = "$installDir$([System.IO.Path]::PathSeparator)$env:PATH"

    # Persist environment (no admin needed)
    if ($IsWindows) {
        [Environment]::SetEnvironmentVariable('DOTNET_ROOT', $installDir, 'User')
        $userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
        if ($userPath -notlike "*$installDir*") {
            [Environment]::SetEnvironmentVariable('PATH', "$installDir;$userPath", 'User')
        }
    }
    else {
        # Append to $PROFILE with markers so Uninstall-Dotnet can remove them
        $marker = '>>> zcap Install-Dotnet >>>'
        $profilePath = $PROFILE.CurrentUserCurrentHost
        $profileExists = Test-Path $profilePath
        $alreadyPatched = $profileExists -and (Get-Content $profilePath -Raw) -match [regex]::Escape($marker)

        if (-not $alreadyPatched) {
            $block = @"

# $marker
`$env:DOTNET_ROOT = "$installDir"
`$env:PATH = "`$env:DOTNET_ROOT$([System.IO.Path]::PathSeparator)`$env:PATH"
# <<< zcap Install-Dotnet <<<
"@
            Add-Content -Path $profilePath -Value $block
        }
    }

    Assert-Command dotnet -ErrorText ".NET SDK was installed but 'dotnet' is not on PATH. You may need to restart your shell."
    Write-Message "Dotnet $Version installed successfully to '$installDir'"
}
