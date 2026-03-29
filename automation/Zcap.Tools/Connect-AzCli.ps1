<#
.SYNOPSIS
    Logs in to Azure CLI.
.DESCRIPTION
    Skips login if already authenticated. Use -Force to re-authenticate.
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
.PARAMETER Force
    Force re-authentication even if already logged in.
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
        [string] $ClientSecret,
        [switch] $Force
    )

    Assert-Tool 'AzCli'

    # Idempotent: skip if already logged in with the correct identity
    # -NoAssert: non-zero exit means "not logged in" — an expected state, not an error
    if (-not $Force) {
        $raw = Invoke-CliCommand 'az account show --output json' -PassThru -NoAssert -Silent
        if ($LASTEXITCODE -eq 0 -and $raw) {
            $account = $raw | ConvertFrom-Json
            $alreadyCorrect = switch ($PSCmdlet.ParameterSetName) {
                'ServicePrincipal' {
                    $account.tenantId -eq $Tenant -and $account.user.name -eq $ClientId
                }
                default { $true }
            }
            if ($alreadyCorrect) {
                Write-Message "Already authenticated as $($account.user.name)"
                return
            }
        }
    }

    # No post-login assertion needed — Invoke-CliCommand throws on non-zero exit
    # codes via Assert-LastExitCodeWasZero. If az login fails, we never reach the
    # Write-Message below.
    Write-Verbose "Authenticating via $($PSCmdlet.ParameterSetName)"
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

    Write-Message "Authenticated via $($PSCmdlet.ParameterSetName)"
}
