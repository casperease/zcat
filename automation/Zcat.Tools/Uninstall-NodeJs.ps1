<#
.SYNOPSIS
    Uninstalls Node.js via the platform package manager.
.DESCRIPTION
    Removes Node.js (and its bundled npm) using the platform package manager.
    Idempotent — skips if not installed.
.PARAMETER Version
    Node.js version to uninstall. Defaults to the locked version in Get-ToolConfig.
.EXAMPLE
    Uninstall-NodeJs
#>
function Uninstall-NodeJs {
    [CmdletBinding()]
    param(
        [string] $Version
    )

    Uninstall-Tool -Tool 'NodeJs' -Version $Version
}
