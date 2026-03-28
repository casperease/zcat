<#
.SYNOPSIS
    Sets the active Azure CLI subscription.
.DESCRIPTION
    Skips if the requested subscription is already active.
.PARAMETER Subscription
    Subscription name or ID.
.EXAMPLE
    Set-AzCliSubscription 'my-subscription'
.EXAMPLE
    Set-AzCliSubscription '00000000-0000-0000-0000-000000000000'
#>
function Set-AzCliSubscription {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Subscription
    )

    Assert-Command az

    # Idempotent: skip if already on the requested subscription
    # -NoAssert: non-zero exit means "not logged in" — falls through to az account set
    $raw = Invoke-CliCommand 'az account show --output json' -PassThru -NoAssert -Silent
    if ($LASTEXITCODE -eq 0 -and $raw) {
        $account = $raw | ConvertFrom-Json
        if ($account.id -eq $Subscription -or $account.name -eq $Subscription) {
            Write-Message "Already on subscription '$Subscription'"
            return
        }
    }

    Write-Verbose "Switching to subscription '$Subscription'"
    Invoke-CliCommand "az account set --subscription $Subscription"

    Write-Message "Active subscription: $Subscription"
}
