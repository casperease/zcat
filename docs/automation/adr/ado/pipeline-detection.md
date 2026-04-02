# ADR: Pipeline detection — how functions adapt to their execution context

## Context

Automation functions run in two contexts: interactively on a developer's machine, and inside an ADO pipeline.
Some behavior must differ between these contexts:

- **Output format.** Pipelines need structured logging (`##vso` commands). Interactive sessions need readable console output.
- **Token source.** Pipelines use `$env:SYSTEM_ACCESSTOKEN`. Local runs use `Get-AzAccessToken` (see [dual-authentication ADR](dual-authentication.md)).
- **Artifact paths.** Pipelines write to `$env:BUILD_ARTIFACTSTAGINGDIRECTORY`. Local runs write to `out/`.
- **Pipeline variables.** `Set-PipelineVariable` emits `##vso` in a pipeline and is a no-op locally (see [pipeline-variables ADR](pipeline-variables.md)).

The question is: how should a function know which context it is in?

### The wrong approach: implicit detection everywhere

If every function that behaves differently in a pipeline has its own `if ($env:BUILD_ARTIFACTSTAGINGDIRECTORY)` check,
the detection logic is scattered and inconsistent. Different functions may check different environment variables,
some may check for the variable's existence while others check its value, and the logic is never tested.

### The right approach: a single detection function

One function answers the question. All other functions call it. The detection logic is in one place,
testable, and the environment variable it checks is an implementation detail.

## Decision

A single `Test-IsRunningInPipeline` function detects the pipeline context.
All context-dependent behavior calls this function — never raw environment variable checks.

### Function

```powershell
function Test-IsRunningInPipeline {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    [bool]$env:BUILD_ARTIFACTSTAGINGDIRECTORY
}
```

`BUILD_ARTIFACTSTAGINGDIRECTORY` is set by the ADO agent on every pipeline run.
It is never set interactively. This makes it a reliable signal.

### Companion: Get-OutputRoot

The most common context-dependent path is the output directory:

```powershell
function Get-OutputRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if (Test-IsRunningInPipeline) {
        $env:BUILD_ARTIFACTSTAGINGDIRECTORY
    }
    else {
        Join-Path (Get-RepositoryRoot) 'out'
    }
}
```

Functions that produce output artifacts call `Get-OutputRoot` instead of hardcoding either path.

### Rules

- **Never check pipeline environment variables directly.** Use `Test-IsRunningInPipeline`. This keeps the detection logic in one place and the checked variable as an implementation detail.

- **Context-dependent behavior must be intentional.** If a function behaves differently in a pipeline, that difference should be visible — either through `Test-IsRunningInPipeline` in the function body, or through a parameter that the caller sets based on context.

- **Prefer parameters over detection.** When a function's behavior can be controlled via a parameter (e.g., `-OutputPath`), prefer that over implicit pipeline detection. Detection is a fallback for cases where the caller cannot reasonably provide the value.

- **Detection is boolean, not modal.** `Test-IsRunningInPipeline` returns `$true` or `$false`. There is no "maybe" or "partially in a pipeline." If the environment variable exists, the code is in a pipeline. If not, it is not.

- **The function must be fast.** It is called frequently (every `Set-PipelineVariable`, every `Get-OutputRoot`, every auth decision). It reads a single environment variable — no I/O, no network, no computation.

### How this is enforced

- **PSScriptAnalyzer custom rule.** A rule flags direct reads of `$env:BUILD_ARTIFACTSTAGINGDIRECTORY`, `$env:TF_BUILD`, or `$env:AGENT_ID` outside of `Test-IsRunningInPipeline`. Context detection must go through the function.

## Consequences

- Pipeline detection is consistent. Every function uses the same check, testing the same variable.
- The checked variable is an implementation detail. If ADO changes its agent variables, one function changes — not every consumer.
- The function is trivially testable: set `$env:BUILD_ARTIFACTSTAGINGDIRECTORY` in a test, assert the result, clean up.
- Context-dependent behavior is greppable: search for `Test-IsRunningInPipeline` to find every place the code branches on execution context.
- Functions that use `Get-OutputRoot` work in both contexts without modification — artifacts land in the right place automatically.
