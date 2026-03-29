<#
.SYNOPSIS
    Removes all tools installed by Install-WorkstationTools.
.DESCRIPTION
    Uninstalls tools in reverse dependency order (AzCli and Poetry depend
    on Python via pip). Idempotent — skips tools that are not installed.
.EXAMPLE
    Uninstall-WorkstationTools
#>
function Uninstall-WorkstationTools {
    [CmdletBinding()]
    param()

    # Reverse of Install-WorkstationTools order. AzCli and Poetry use pip (which
    # needs Python), so uninstall them before Python.
    Uninstall-NodeJs
    Uninstall-AzCli
    Uninstall-Poetry
    Uninstall-Dotnet
    Uninstall-Python
}
