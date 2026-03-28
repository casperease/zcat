<#
.SYNOPSIS
    Removes all tools installed by Install-Tools.
.DESCRIPTION
    Uninstalls tools in reverse dependency order (AzCli and Poetry depend
    on Python via pip). Idempotent — skips tools that are not installed.
.EXAMPLE
    Uninstall-Tools
#>
function Uninstall-Tools {
    [CmdletBinding()]
    param()

    # Reverse of Install-Tools order. AzCli and Poetry use pip (which
    # needs Python), so uninstall them before Python.
    Uninstall-AzCli
    Uninstall-Poetry
    Uninstall-Dotnet
    Uninstall-Python
}
