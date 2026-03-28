<#
.SYNOPSIS
    Uninstalls Poetry via pip.
.PARAMETER Version
    Poetry version to uninstall. Defaults to the locked version in Get-ToolConfig.
.EXAMPLE
    Uninstall-Poetry
#>
function Uninstall-Poetry {
    [CmdletBinding()]
    param(
        [string] $Version
    )

    $config = Get-ToolConfig -Tool 'Poetry'
    if (-not $Version) { $Version = $config.Version }

    Invoke-Pip "uninstall $($config.PipPackage) -y"

    Write-Message "Poetry $Version uninstalled"
}
