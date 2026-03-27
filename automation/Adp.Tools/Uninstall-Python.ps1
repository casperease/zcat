<#
.SYNOPSIS
    Uninstalls Python via the platform package manager.
.PARAMETER Version
    Python version to uninstall. Defaults to the locked version in Get-ToolConfig.
.EXAMPLE
    Uninstall-Python
.EXAMPLE
    Uninstall-Python -Version '3.12'
#>
function Uninstall-Python {
    [CmdletBinding()]
    param(
        [string] $Version
    )

    Uninstall-Tool -Tool 'Python' -Version $Version
}
