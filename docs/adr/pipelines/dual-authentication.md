# ADR: Dual authentication — pipeline system token vs. local Az token

## Context

Automation code that calls Azure DevOps REST APIs (environments, approvals, wikis) or Azure Resource Manager
needs a bearer token. The token source depends on where the code runs:

- **In a pipeline:** ADO injects `System.AccessToken` — a short-lived OAuth token scoped to the pipeline's identity.
  It is available as `$env:SYSTEM_ACCESSTOKEN` when the step template maps it explicitly.

- **On a developer machine:** The developer is authenticated via `az login` or `Connect-AzAccount`.
  Tokens are obtained at runtime via `Get-AzAccessToken` or `az account get-access-token`.

These are fundamentally different credential flows. Code that assumes one will break in the other context.
The wrong abstraction here — a single "get me a token" function that tries both and guesses — leads to
silent auth failures that manifest as opaque 401s.

### Why this matters

A function calling the ADO REST API must include an `Authorization: Bearer <token>` header.
If the function hardcodes `$env:SYSTEM_ACCESSTOKEN`, it fails locally.
If it hardcodes `Get-AzAccessToken`, it fails in the pipeline (the Az module may not be installed,
or the managed identity may not have the right scope).

The dual-auth pattern makes the token source explicit and deterministic.

## Decision

Functions that need authentication accept a token parameter with a well-defined fallback chain.
The fallback is deterministic: pipeline token first, then local token. There is no guessing.

### Pattern

```powershell
function Get-AdoAuthorizationHeader {
    [CmdletBinding()]
    param()

    $token = if (Test-IsRunningInPipeline) {
        $env:SYSTEM_ACCESSTOKEN
    }
    else {
        (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798').Token
    }

    Assert-NotNullOrWhitespace $token -ErrorText (
        'No ADO token available. ' +
        'In a pipeline, ensure SYSTEM_ACCESSTOKEN is mapped. ' +
        'Locally, run Connect-AzAccount first.'
    )

    @{ 'Authorization' = "Bearer $token" }
}
```

The resource URL `499b84ac-1321-427f-aa17-267ca6975798` is Azure DevOps's well-known resource ID.
For Azure Resource Manager calls, use `https://management.azure.com/` instead.

### Rules

- **Pipeline detection is explicit.** Use `Test-IsRunningInPipeline` (see [pipeline-detection ADR](pipeline-detection.md)) to choose the token source. Never try one and fall back to the other on failure — that masks auth misconfiguration.

- **Token acquisition is a separate function.** API-calling functions do not inline token logic. They call a dedicated auth function (`Get-AdoAuthorizationHeader`, `Get-AzAuthorizationHeader`) that encapsulates the dual-source pattern.

- **Assert on the token.** After acquiring the token, assert it is not null or empty. The error message must name both possible causes: missing `SYSTEM_ACCESSTOKEN` mapping (pipeline) or missing `az login` (local).

- **Step templates map the system token.** The `invoke-powershell.yaml` step template includes `SYSTEM_ACCESSTOKEN: $(System.AccessToken)` as an environment variable. Functions never access `System.AccessToken` directly — they read the mapped `$env:SYSTEM_ACCESSTOKEN`.

- **Never store tokens in variables beyond the request.** Acquire the token, build the header, make the call. Do not cache tokens in `$script:` variables or pass them between functions — they are short-lived and caching complicates refresh.

### Step template integration

```yaml
# invoke-powershell.yaml (with auth)
parameters:
  - name: RunCommand
    type: string
  - name: UseSystemAccessToken
    type: boolean
    default: false

steps:
  - task: PowerShell@2
    inputs:
      filePath: pipelines/Invoke-AdoScript.ps1
      arguments: -Command '${{ parameters.RunCommand }}'
    env:
      ${{ if parameters.UseSystemAccessToken }}:
        SYSTEM_ACCESSTOKEN: $(System.AccessToken)
```

The token is only mapped when `UseSystemAccessToken` is true.
This makes it visible in the YAML which steps have ADO API access — a useful security audit trail.

## Consequences

- Token source is deterministic. Pipeline runs use the system token; local runs use the Az login. No ambiguity.
- Auth failures produce clear error messages naming the specific missing credential.
- Functions are portable — they run in both contexts without modification.
- The step template controls token visibility, making it auditable which pipeline steps have API access.
- No token caching or refresh logic — tokens are acquired fresh per call, matching their short-lived nature.
