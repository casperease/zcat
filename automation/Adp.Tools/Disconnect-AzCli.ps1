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

    Assert-Command az

    # Idempotent: skip if not logged in
    $account = Invoke-CliCommand 'az account show --output json' -PassThru -NoAssert -Silent
    if ($LASTEXITCODE -ne 0 -or -not $account) {
        Write-Verbose 'Not logged in'
        return
    }

    Invoke-CliCommand 'az logout'
}
