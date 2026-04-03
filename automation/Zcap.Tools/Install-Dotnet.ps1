<#
.SYNOPSIS
    Installs the .NET SDK via official Microsoft install scripts (user-space).
.DESCRIPTION
    Uses vendored dotnet-install scripts instead of package managers.
    Install directory resolved by Get-ScriptInstallDir (LOCALAPPDATA on
    Windows, HOME on Unix — overridable in tools.yml).
    No admin required. Persists DOTNET_ROOT and PATH for future sessions.
    Idempotent — if the correct version is already on PATH (regardless of
    how it was installed), skips with a message.

    NOT for CI pipelines. In Azure DevOps, use the native UseDotNet task
    which activates pre-cached versions instantly:

        - task: UseDotNet@2
          inputs:
            version: '10.x'
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

    Assert-False (Test-IsRunningInPipeline) -ErrorText (
        "Install-Dotnet is for developer workstations, not CI. " +
        "In ADO pipelines, use the native task: - task: UseDotNet@2 inputs: version: '10.x'"
    )

    $config = Get-ToolConfig -Tool 'Dotnet'
    if (-not $Version) { $Version = $config.Version }

    # Same rule as all other tools: if the correct version is on PATH, skip.
    if (Test-Command $config.Command) {
        $installed = Get-ToolVersion -Config $config

        if ($installed -and $installed.StartsWith($Version)) {
            Write-Message "Dotnet $Version is already installed"
            return
        }

        # Wrong version on PATH — only matters if it's from our install dir.
        # A system-wide dotnet at a different version doesn't block us since
        # we install side-by-side and prepend our dir to PATH.
    }

    $installDir = Get-ScriptInstallDir -Config $config
    $ourBinary = if ($IsWindows) { Join-Path $installDir 'dotnet.exe' } else { Join-Path $installDir 'dotnet' }

    # Check our install dir for wrong-version scenario
    if (Test-Path $ourBinary) {
        # Check specific binary (not PATH) — can't use Get-ToolVersion here
        $result = Invoke-CliCommand "$ourBinary --version" -PassThru -NoAssert -Silent
        $ourInstalled = if ($result.Full -match $config.VersionPattern) { $Matches['ver'] } else { $null }

        if ($ourInstalled -and $ourInstalled.StartsWith($Version)) {
            Write-Message "Dotnet $Version is already installed at '$installDir'"
            return
        }

        if ($Force) {
            Write-Verbose "Dotnet $ourInstalled found at '$installDir' — reinstalling $Version"
        }
        else {
            throw "Dotnet version mismatch: expected $Version.x, found $ourInstalled at '$installDir'. Run Install-Dotnet -Force to replace."
        }
    }

    # Resolve vendored install script
    if ($IsWindows) {
        $scriptPath = Join-Path $PSScriptRoot 'assets' 'scripts' 'dotnet-install.ps1'
        Assert-PathExist $scriptPath
        Write-Message "Installing .NET SDK $Version to '$installDir'"
        & $scriptPath -Channel $Version -InstallDir $installDir -Quality ga
    }
    else {
        $scriptPath = Join-Path $PSScriptRoot 'assets' 'scripts' 'dotnet-install.sh'
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
