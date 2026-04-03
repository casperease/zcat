# ADR: Pipeline variable interface — setting ADO output variables from PowerShell

## Context

Azure DevOps pipelines communicate between steps and jobs through pipeline variables.
The mechanism is a logging command written to stdout:

```
##vso[task.setvariable variable=MyVar;isOutput=true]MyValue
```

This syntax is awkward, error-prone, and has several sharp edges:

- **Variable name sanitization.** ADO silently replaces `.`, `-`, and `'` with `_` when resolving variable references,
  but the `##vso` command accepts the original characters. A variable set as `my.var` must be referenced as `my_var` downstream.
  If the setter and consumer use different conventions, the variable silently resolves to empty.

- **Output vs. local scope.** Without `isOutput=true`, the variable is local to the current step.
  To pass it to another job, it must be an output variable — but the syntax is easy to forget.

- **Secret masking.** `issecret=true` tells ADO to mask the value in logs.
  Forgetting this for sensitive values leaks them to the build log.

- **No validation.** The `##vso` command never fails — if you misspell a flag or omit a value,
  the variable is silently not set and downstream steps see an empty string.

### Why this needs a function

Every one of these sharp edges has caused real pipeline debugging sessions.
A function that handles sanitization, output flags, and secret marking eliminates them structurally.
The function also makes pipeline variable usage visible to PSScriptAnalyzer, testable in Pester,
and greppable in the codebase — none of which is true for raw `##vso` strings scattered through scripts.

## Decision

Pipeline variable manipulation is done through dedicated PowerShell functions, never through raw `##vso` logging commands.

### Functions

**`Set-AdoPipelineVariable`** — sets a pipeline variable with proper sanitization and flags.

```powershell
function Set-AdoPipelineVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Value,
        [switch] $IsOutput,
        [switch] $IsSecret
    )
    # ...
}
```

Behavior:
- Sanitizes the variable name: replaces `.`, `-`, `'` with `_` to match ADO's downstream resolution.
- Emits the `##vso[task.setvariable]` command with correct flags.
- Logs the variable name and value via `Write-Message` (unless `$IsSecret`, in which case the value is omitted).
- Throws if `$Name` is null or whitespace.

**`Test-IsRunningInPipeline`** — gates pipeline-specific behavior (see [pipeline-detection ADR](pipeline-detection.md)).
`Set-AdoPipelineVariable` uses this internally — calling it outside a pipeline is a no-op with a verbose message, not an error.
This keeps automation code portable: the same function runs locally (silently skipping the `##vso` command)
and in a pipeline (emitting it).

### Rules

- **Never write raw `##vso[task.setvariable]` strings.** Use `Set-AdoPipelineVariable`. The function handles sanitization, flags, and logging.

- **Always use `-IsOutput` when the variable must cross job boundaries.** Without it, the variable is step-local and downstream jobs see an empty string.

- **Always use `-IsSecret` for sensitive values.** This masks the value in ADO logs. The function enforces this by omitting the value from its own `Write-Message` output when the flag is set.

- **Variable names use PascalCase.** ADO variable names are case-insensitive, but PascalCase matches the PowerShell parameter convention and reads clearly in YAML: `$[dependencies.JobName.outputs['StepName.MyVariable']]`.

- **No-op outside pipelines.** `Set-AdoPipelineVariable` checks `Test-IsRunningInPipeline` and skips the `##vso` emission when running locally. This means automation code does not need `if (Test-IsRunningInPipeline)` guards at every call site.

### How this is enforced

- **PSScriptAnalyzer custom rule.** A rule flags any string matching `##vso\[task\.setvariable` outside of `Set-AdoPipelineVariable`. Raw logging commands in automation code are a linting error.

## Consequences

- Variable name sanitization is automatic. No more debugging empty variables caused by `.` vs `_` mismatches.
- Secret masking is a flag, not a syntax detail to remember. Sensitive values cannot be accidentally logged.
- Pipeline variable usage is greppable: search for `Set-AdoPipelineVariable` to find every variable the automation sets.
- The same code runs locally and in pipelines without conditional guards. Local runs silently skip the ADO commands.
- Output variable semantics are explicit in the function call, not hidden in a `##vso` flag string.
