<#
.SYNOPSIS
    Installs Python via the platform package manager.
.PARAMETER Version
    Python version to install. Defaults to the locked version in Get-ToolConfig.
.EXAMPLE
    Install-Python
.EXAMPLE
    Install-Python -Version '3.12'
#>
function Install-Python {
    [CmdletBinding()]
    param(
        [string] $Version
    )

    Install-Tool -Tool 'Python' -Version $Version
}
