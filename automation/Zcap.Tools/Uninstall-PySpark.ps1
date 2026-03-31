<#
.SYNOPSIS
    Uninstalls PySpark via pip.
.DESCRIPTION
    Idempotent — skips if PySpark is not installed or if Python is
    not available (nothing to pip-uninstall).
.EXAMPLE
    Uninstall-PySpark
#>
function Uninstall-PySpark {
    [CmdletBinding()]
    param()

    Uninstall-PipTool -Tool 'PySpark'
}
