<#
.SYNOPSIS
    Returns an Authorization header for Azure DevOps REST API calls.
.DESCRIPTION
    Authentication sources, in priority order:
    1. Pipeline: $env:SYSTEM_ACCESSTOKEN (mapped in the step template) — Bearer token.
    2. PAT: $env:AZURE_DEVOPS_PAT — Basic auth with base64-encoded PAT.
    3. az CLI: az account get-access-token for the ADO resource — Bearer token.

    Returns a hashtable suitable for splatting into Invoke-RestMethod -Headers.
.PARAMETER ResourceUrl
    The Azure AD resource URL for az CLI token requests.
    Defaults to the Azure DevOps resource ID (499b84ac-1321-427f-aa17-267ca6975798).
.EXAMPLE
    $headers = Get-AdoAuthorizationHeader
    Invoke-RestMethod -Uri $url -Headers $headers
#>
function Get-AdoAuthorizationHeader {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string] $ResourceUrl = '499b84ac-1321-427f-aa17-267ca6975798'
    )

    if ((Test-IsRunningInPipeline) -and $env:SYSTEM_ACCESSTOKEN) {
        return @{ 'Authorization' = "Bearer $env:SYSTEM_ACCESSTOKEN" }
    }

    if ($env:AZURE_DEVOPS_PAT) {
        $base64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$env:AZURE_DEVOPS_PAT"))
        return @{ 'Authorization' = "Basic $base64" }
    }

    Assert-AzCliConnected
    $result = Invoke-CliCommand "az account get-access-token --resource $ResourceUrl --query accessToken -o tsv" -PassThru -Silent
    Assert-NotNullOrWhitespace $result.Output -ErrorText (
        'No ADO token available. Set $env:AZURE_DEVOPS_PAT, or run Connect-AzCli with an Entra ID account.'
    )

    @{ 'Authorization' = "Bearer $($result.Output)" }
}
