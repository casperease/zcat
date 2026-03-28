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

    $config = Get-ToolConfig -Tool 'Poetry'

    # Idempotent: skip if poetry is not installed
    if (-not (Test-Command $config.Command)) {
        Write-Message "Poetry is not installed — nothing to do"
        return
    }

    Invoke-Pip "uninstall $($config.PipPackage) -y"
    Write-Message "Poetry uninstalled"
}
