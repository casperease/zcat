<#
.SYNOPSIS
    Removes all devbox tools installed by Install-DevBox.
.DESCRIPTION
    Uninstalls tools in reverse dependency order (AzCli and Poetry depend
    on Python via pip). Idempotent — skips tools that are not installed.
.EXAMPLE
    Uninstall-DevBox
#>
function Uninstall-DevBox {
    [CmdletBinding()]
    param()

    # Reverse of Install-DevBox order. AzCli and Poetry use pip (which
    # needs Python), so uninstall them before Python.
    Uninstall-AzCli
    Uninstall-Poetry
    Uninstall-Dotnet
    Uninstall-Python
}
