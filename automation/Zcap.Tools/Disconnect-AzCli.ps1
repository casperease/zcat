<#
.SYNOPSIS
    Logs out of Azure CLI.
.DESCRIPTION
    Skips if not currently logged in.
.EXAMPLE
    Disconnect-AzCli
#>
function Disconnect-AzCli {
    [CmdletBinding()]
    param()

    Assert-Tool 'AzCli'

    # Idempotent: skip if not logged in
    # -NoAssert: non-zero exit means "not logged in" — an expected state, not an error
    $account = Invoke-CliCommand 'az account show --output json' -PassThru -NoAssert -Silent
    if ($LASTEXITCODE -ne 0 -or -not $account) {
        Write-Message 'Not logged in — nothing to do'
        return
    }

    Invoke-CliCommand 'az logout'

    Write-Message 'Logged out of Azure CLI'
}
