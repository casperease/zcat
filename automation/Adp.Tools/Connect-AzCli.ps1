<#
.SYNOPSIS
    Logs in to Azure CLI.
.PARAMETER ServicePrincipal
    Login as a service principal. Requires Tenant, ClientId, and ClientSecret.
.PARAMETER ManagedIdentity
    Login using managed identity.
.PARAMETER DeviceCode
    Login using device code flow (for environments without a browser).
.PARAMETER Tenant
    Azure AD tenant ID. Required for service principal login.
.PARAMETER ClientId
    Service principal app/client ID. Required for service principal login.
.PARAMETER ClientSecret
    Service principal secret. Required for service principal login.
.EXAMPLE
    Connect-AzCli
.EXAMPLE
    Connect-AzCli -DeviceCode
.EXAMPLE
    Connect-AzCli -ServicePrincipal -Tenant $t -ClientId $id -ClientSecret $secret
.EXAMPLE
    Connect-AzCli -ManagedIdentity
#>
function Connect-AzCli {
    [CmdletBinding(DefaultParameterSetName = 'Interactive')]
    param(
        [Parameter(ParameterSetName = 'ServicePrincipal', Mandatory)]
        [switch] $ServicePrincipal,

        [Parameter(ParameterSetName = 'ManagedIdentity', Mandatory)]
        [switch] $ManagedIdentity,

        [Parameter(ParameterSetName = 'DeviceCode', Mandatory)]
        [switch] $DeviceCode,

        [Parameter(ParameterSetName = 'ServicePrincipal', Mandatory)]
        [string] $Tenant,

        [Parameter(ParameterSetName = 'ServicePrincipal', Mandatory)]
        [string] $ClientId,

        [Parameter(ParameterSetName = 'ServicePrincipal', Mandatory)]
        [string] $ClientSecret
    )

    Assert-Command az
    Assert-ToolVersion -Tool 'AzCli'

    switch ($PSCmdlet.ParameterSetName) {
        'ServicePrincipal' {
            Invoke-CliCommand "az login --service-principal --tenant $Tenant --username $ClientId --password $ClientSecret"
        }
        'ManagedIdentity' {
            Invoke-CliCommand 'az login --identity'
        }
        'DeviceCode' {
            Invoke-CliCommand 'az login --use-device-code'
        }
        'Interactive' {
            Invoke-CliCommand 'az login'
        }
    }
}
