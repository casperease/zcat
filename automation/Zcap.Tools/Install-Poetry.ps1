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

    Install-PipTool -Tool 'Poetry' -Version $Version
}
