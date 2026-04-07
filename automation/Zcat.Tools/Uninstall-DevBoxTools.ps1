<#
.SYNOPSIS
    Removes all tools installed by Install-DevBoxTools.
.DESCRIPTION
    Uninstalls tools in reverse dependency order (derived from DependsOn
    in tools.yml). Tools that depend on others are removed first so their
    uninstallers can still use the dependency (e.g., pip tools need Python).
    Idempotent — skips tools that are not installed.
.EXAMPLE
    Uninstall-DevBoxTools
#>
function Uninstall-DevBoxTools {
    [CmdletBinding()]
    param()

    # Additional tools first (no dependencies on version-locked tools)
    Uninstall-Postman
    Uninstall-Git

    # Version-locked tools in reverse dependency order
    $order = Get-ToolInstallOrder
    [array]::Reverse($order)

    foreach ($toolName in $order) {
        $uninstallCmd = "Uninstall-$toolName"
        if (Get-Command $uninstallCmd -ErrorAction SilentlyContinue) {
            & $uninstallCmd
        }
    }
}
