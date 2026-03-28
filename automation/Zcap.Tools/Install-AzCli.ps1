<#
.SYNOPSIS
    Installs the Azure CLI via the platform package manager.
.PARAMETER Version
    Azure CLI version to install. Defaults to the locked version in Get-ToolConfig.
.EXAMPLE
    Install-AzCli
.EXAMPLE
    Install-AzCli -Version '2.74'
#>
function Install-AzCli {
    [CmdletBinding()]
    param(
        [string] $Version
    )

    Install-Tool -Tool 'AzCli' -Version $Version
}
