<#
.SYNOPSIS
    Returns an array of environment type shortnames (core, workspace_sub, etc.).
.PARAMETER Scope
    Filter by scope: Customer, Shared, or All. Defaults to All.
.EXAMPLE
    Get-MetaEnvironmentTypes
.EXAMPLE
    Get-MetaEnvironmentTypes -Scope Customer
#>
function Get-MetaEnvironmentTypes {
    [CmdletBinding()]
    param(
        [ValidateSet('All', 'Customer', 'Shared')]
        [string] $Scope = 'All'
    )

    $types = (Get-MetaConfiguration).environment_types

    switch ($Scope) {
        'Customer' { @($types.customer.Keys) }
        'Shared'   { @($types.shared.Keys) }
        'All'      { @($types.customer.Keys) + @($types.shared.Keys) }
    }
}
