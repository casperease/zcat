<#
.SYNOPSIS
    Returns an array of customer shortnames.
.EXAMPLE
    Get-MetaCustomers
#>
function Get-MetaCustomers {
    [CmdletBinding()]
    param()

    @((Get-MetaConfiguration).customers.Keys)
}
