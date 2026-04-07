<#
.SYNOPSIS
    Uninstalls Terraform via the platform package manager.
.PARAMETER Version
    Terraform version to uninstall. Defaults to the locked version in Get-ToolConfig.
.EXAMPLE
    Uninstall-Terraform
#>
function Uninstall-Terraform {
    [CmdletBinding()]
    param(
        [string] $Version
    )

    Uninstall-Tool -Tool 'Terraform' -Version $Version
}
