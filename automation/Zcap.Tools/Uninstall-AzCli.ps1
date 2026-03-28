<#
.SYNOPSIS
    Uninstalls the Azure CLI via the platform package manager.
.PARAMETER Version
    Azure CLI version to uninstall. Defaults to the locked version in Get-ToolConfig.
.EXAMPLE
    Uninstall-AzCli
.EXAMPLE
    Uninstall-AzCli -Version '2.74'
#>
function Uninstall-AzCli {
    [CmdletBinding()]
    param(
        [string] $Version
    )

    Uninstall-Tool -Tool 'AzCli' -Version $Version
}
