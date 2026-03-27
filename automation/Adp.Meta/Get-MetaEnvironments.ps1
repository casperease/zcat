<#
.SYNOPSIS
    Returns an array of environment shortnames (dev, test, preprod, prod).
.EXAMPLE
    Get-MetaEnvironments
#>
function Get-MetaEnvironments {
    [CmdletBinding()]
    param()

    @((Get-MetaConfiguration).environments.Keys)
}
