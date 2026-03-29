<#
.SYNOPSIS
    Installs or upgrades npm to the locked version.
.DESCRIPTION
    npm ships with Node.js. This function upgrades it to the version
    locked in Get-ToolConfig via npm install -g. Requires Node.js on PATH.
    Idempotent — skips if the correct version is already installed.
.PARAMETER Version
    npm version to install. Defaults to the locked version in Get-ToolConfig.
.PARAMETER Force
    Replace an existing installation at the wrong version.
.EXAMPLE
    Install-Npm
.EXAMPLE
    Install-Npm -Version '11.12'
#>
function Install-Npm {
    [CmdletBinding()]
    param(
        [string] $Version,
        [switch] $Force
    )

    $config = Get-ToolConfig -Tool 'Npm'
    if (-not $Version) { $Version = $config.Version }

    Assert-Command node -ErrorText "npm requires Node.js — install Node.js first"

    if (Test-Command $config.Command) {
        $raw = Invoke-CliCommand $config.VersionCommand -PassThru -NoAssert -Silent 2>$null
        $installed = if ($raw -match $config.VersionPattern) { $Matches['ver'] } else { $null }

        if ($installed -and $installed.StartsWith($Version)) {
            Write-Message "npm $Version is already installed"
            return
        }

        if (-not $Force) {
            throw "npm version mismatch: expected $Version.x, found $installed. Run Install-Npm -Force to replace."
        }
    }

    Invoke-CliCommand "npm install -g npm@$Version"

    Assert-Command $config.Command
    Assert-ToolVersion -Tool 'Npm'
    Write-Message "npm $Version installed successfully"
}
