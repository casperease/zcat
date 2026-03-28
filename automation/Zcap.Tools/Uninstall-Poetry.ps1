<#
.SYNOPSIS
    Uninstalls Poetry via pip.
.DESCRIPTION
    Idempotent — skips if Poetry is not installed or if Python is
    not available (nothing to pip-uninstall).
.EXAMPLE
    Uninstall-Poetry
#>
function Uninstall-Poetry {
    [CmdletBinding()]
    param()

    Uninstall-PipTool -Tool 'Poetry'
}
