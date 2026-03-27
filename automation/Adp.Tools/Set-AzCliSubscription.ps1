<#
.SYNOPSIS
    Sets the active Azure CLI subscription.
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
    Invoke-CliCommand "az account set --subscription $Subscription"
}
