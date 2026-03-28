<#
.SYNOPSIS
    Installs Poetry via pip.
.PARAMETER Version
    Poetry version to install. Defaults to the locked version in Get-ToolConfig.
.EXAMPLE
    Install-Poetry
.EXAMPLE
    Install-Poetry -Version '2.0'
#>
function Install-Poetry {
    [CmdletBinding()]
    param(
        [string] $Version
    )

    $config = Get-ToolConfig -Tool 'Poetry'
    if (-not $Version) { $Version = $config.Version }

    # Idempotent: skip if already installed at the correct version
    if (Test-Command $config.Command) {
        $raw = Invoke-CliCommand $config.VersionCommand -PassThru -NoAssert -Silent 2>$null
        if ($raw -match $config.VersionPattern -and $Matches['ver'].StartsWith($Version)) {
            Write-Message "Poetry $Version is already installed"
            return
        }
    }

    Invoke-Pip "install $($config.PipPackage)==$Version.*"

    Assert-Command $config.Command -ErrorText "Poetry was installed but '$($config.Command)' is not on PATH. You may need to restart your shell."
    Write-Message "Poetry $Version installed successfully"
}
