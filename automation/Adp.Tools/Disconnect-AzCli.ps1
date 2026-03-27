<#
.SYNOPSIS
    Logs out of Azure CLI.
.EXAMPLE
    Disconnect-AzCli
#>
function Disconnect-AzCli {
    [CmdletBinding()]
    param()

    Assert-Command az
    Invoke-CliCommand 'az logout'
}
