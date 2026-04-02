<#
.SYNOPSIS
    Returns an Authorization header for Azure DevOps REST API calls.
.DESCRIPTION
    Implements the dual authentication pattern:
    - In a pipeline: uses $env:SYSTEM_ACCESSTOKEN (must be mapped in the step template).
    - Locally: uses Get-AzAccessToken with the Azure DevOps resource ID.

    Returns a hashtable suitable for splatting into Invoke-RestMethod -Headers.
.PARAMETER ResourceUrl
    The Azure AD resource URL to request a token for.
    Defaults to the Azure DevOps resource ID (499b84ac-1321-427f-aa17-267ca6975798).
    Use 'https://management.azure.com/' for Azure Resource Manager calls.
.EXAMPLE
    $headers = Get-AdoAuthorizationHeader
    Invoke-RestMethod -Uri $url -Headers $headers
.EXAMPLE
    $headers = Get-AdoAuthorizationHeader -ResourceUrl 'https://management.azure.com/'
#>
function Get-AdoAuthorizationHeader {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string] $ResourceUrl = '499b84ac-1321-427f-aa17-267ca6975798'
    )

    $token = if (Test-IsRunningInPipeline) {
        $env:SYSTEM_ACCESSTOKEN
    }
    else {
        Assert-PsModule 'Az.Accounts' -ErrorText (
            'Az.Accounts module is required for local ADO authentication. ' +
            'Run Connect-AzAccount first.'
        )
        (Get-AzAccessToken -ResourceUrl $ResourceUrl).Token
    }

    Assert-NotNullOrWhitespace $token -ErrorText (
        'No ADO token available. ' +
        'In a pipeline, ensure SYSTEM_ACCESSTOKEN is mapped in the step template. ' +
        'Locally, run Connect-AzAccount first.'
    )

    @{ 'Authorization' = "Bearer $token" }
}
