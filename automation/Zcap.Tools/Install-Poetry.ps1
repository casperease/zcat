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

    Invoke-Pip "install $($config.PipPackage)==$Version.*"

    Assert-Command $config.Command -ErrorText "Poetry was installed but '$($config.Command)' is not on PATH. You may need to restart your shell."
    Write-Message "Poetry $Version installed successfully"
}
