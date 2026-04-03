# ADR: Environment variables are for external boundaries, not internal state

## Context

PowerShell makes `$env:` variables dangerously convenient.
They look like regular variables, they are accessible everywhere, and they survive function calls.
This makes them tempting for passing state between functions, caching results, or storing configuration.

That temptation is the problem. Environment variables are the worst form of global mutable state because they have
**no scoping, no type safety, no automatic cleanup, and no visibility boundaries.**

PowerShell has proper scoping for regular variables: `$local:`, `$script:`, module scope, function parameters, return values.
All of these are destroyed or scoped automatically. `$env:FOO` set inside any function, at any call depth,
persists for the entire process lifetime unless someone explicitly removes it.
There is no `try`/`finally` equivalent that automatically cleans up environment variables when a scope exits.

### Why environment variables are global mutable state

- **Global.** `$env:FOO` is readable and writable from any function, any module, any scope.
  There is no access control. Any code — yours, vendored, third-party — can read or mutate any environment variable.
  This couples all code together: you must reason about the entire process, not just the function you are reading.

- **Mutable.** Any code path can change the value at any time.
  Two consecutive reads of `$env:FOO` can return different values if something in between modified it.

- **Unscoped.** Unlike `$script:` variables (scoped to the module) or `$local:` variables (scoped to the function),
  `$env:` has no boundaries at all. It bypasses PowerShell's scope isolation entirely.

### They are always strings

`$env:` values are always strings. There is no type safety.
`$env:COUNT = 42` stores the string `"42"`. `$env:ENABLED = $true` stores the string `"True"`.
Every consumer must parse and validate. There is no schema, no constraint, no `[ValidateSet()]`.
Compare this to a function parameter with `[int]`, `[switch]`, or `[ValidateRange()]` — the type system catches errors at the call site.

### They leak to child processes

Every process spawned via `Start-Process`, `Start-Job`, `&`, or external tool invocation inherits
**all** environment variables from the parent.
A child process (a linter, a build tool, a third-party CLI) sees every `$env:` variable the parent set,
even if it has no need for them.
This violates least privilege and creates an invisible coupling between parent and child.

### They break parallel execution

All runspaces in a `ForEach-Object -Parallel` block share the same process environment block.
Environment variables are not isolated per runspace — they are process-wide.
Concurrent reads and writes to the same `$env:` variable from different runspaces produce race conditions.
Unlike `$using:` variables (which are copied per-runspace), `$env:` is a single shared namespace.

### They poison tests

Environment variables set in one test leak into subsequent tests.
If Test A sets `$env:MODE = 'test'` and forgets to clean up, Test B runs with an unexpected `$env:MODE`.
This creates order-dependent test failures that are extremely difficult to diagnose.

Pester provides `TestDrive:` for file isolation and scoped cleanup for PowerShell variables,
but it provides **no automatic isolation for environment variables.**
You must manually snapshot and restore them — ceremony that proper function parameters would avoid entirely.

### They are a security surface

Environment variables are visible to all child processes, can be dumped via `/proc/<pid>/environ` on Linux
or process inspection tools on Windows, and are frequently logged by CI systems and error-reporting frameworks.
MITRE classifies "Cleartext Storage of Sensitive Information in an Environment Variable" as CWE-526.
Never store secrets, tokens, or credentials in `$env:` variables. Use secret managers or secure parameter passing.

### Case sensitivity is inconsistent

`$env:Path` and `$env:PATH` refer to the same variable on Windows but different variables on Linux.
Using environment variables for internal state means dealing with this cross-platform inconsistency in every consumer.
Module-scoped variables have no such problem.

### The correct alternative for internal state

| Mechanism            | Scope   | Cleanup        | Type-safe    | Testable                  |
| -------------------- | ------- | -------------- | ------------ | ------------------------- |
| Function parameters  | Call    | Automatic      | Yes          | Trivially                 |
| Return values        | Call    | Automatic      | Yes          | Trivially                 |
| `$script:` variables | Module  | Module unload  | Yes          | Mockable                  |
| `$env:` variables    | Process | Never (manual) | No (strings) | Requires snapshot/restore |

If you need to pass a value between functions, pass it as a parameter.
If you need to share state within a module, use `$script:`.
If you need to cache a result, use a module-scoped variable.
None of these leak to child processes, pollute tests, or persist beyond their natural lifetime.

## Decision

Environment variables are used exclusively at external boundaries — never as internal state between our own functions.

### Legitimate uses

These are the only acceptable patterns for `$env:` in our code:

**1. Setting variables for external tools to consume.**
External tools define their configuration contract through environment variables.
We set these so the tool behaves correctly:

```powershell
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'     # dotnet CLI reads this
$env:GIT_TERMINAL_PROMPT = '0'             # git reads this
$env:AZURE_CONFIG_DIR = $configPath         # Azure CLI reads this
$env:PSModulePath = $vendorPaths            # PowerShell reads this
```

The key distinction: the _consumer_ of the variable is an external process, not our code.

**2. Reading variables that external systems set.**
CI platforms, container runtimes, and operating systems communicate via environment variables.
Reading these is fine — they are inputs from outside our boundary:

```powershell
$env:TF_BUILD          # set by Azure DevOps — are we in a pipeline?
$env:GITHUB_ACTIONS    # set by GitHub Actions — are we in a workflow?
$env:SystemRoot        # set by Windows — where is the OS?
```

**3. Setting a well-known anchor once at bootstrap.**
`$env:RepositoryRoot` is set by `importer.ps1` at startup and never modified again.
It is effectively a constant — a process-wide anchor that replaces dependency on `$PWD`.
This is acceptable because it is set once, never mutated, and serves the same role as a tool's
contract variable (every function needs a stable root, and `$env:` is the only mechanism that
crosses module boundaries without passing parameters through every call).

### Prohibited uses

**Never use `$env:` as internal state between our own functions:**

```powershell
# BAD — passing state through the environment
function Install-Tool {
    # ...install logic...
    $env:LAST_INSTALLED_TOOL = $toolName      # leaks to every child process
}
function Show-Summary {
    Write-Host "Installed: $env:LAST_INSTALLED_TOOL"  # invisible coupling
}

# GOOD — pass it as a return value or parameter
function Install-Tool {
    # ...install logic...
    return $toolName
}
$installed = Install-Tool -Name 'python'
Show-Summary -ToolName $installed
```

**Never use `$env:` as a cache or flag:**

```powershell
# BAD — caching in the environment
function Get-Config {
    if ($env:CONFIG_LOADED) { return $script:CachedConfig }
    $script:CachedConfig = Import-PowerShellDataFile $path
    $env:CONFIG_LOADED = '1'
    return $script:CachedConfig
}

# GOOD — module-scoped variable, no env var needed
function Get-Config {
    if ($script:CachedConfig) { return $script:CachedConfig }
    $script:CachedConfig = Import-PowerShellDataFile $path
    return $script:CachedConfig
}
```

**Never use `$env:` to gate functionality:**

```powershell
# BAD — "if this env is not defined, we don't work"
function Deploy-App {
    if (-not $env:DEPLOY_TARGET) {
        throw 'Set $env:DEPLOY_TARGET before calling Deploy-App'
    }
}

# GOOD — make it a parameter with validation
function Deploy-App {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('staging', 'production')]
        [string] $Target
    )
}
```

The parameter approach gives you type validation, tab completion, mandatory enforcement,
and documentation — all for free. The `$env:` approach gives you a stringly-typed global
that the caller has to know about by reading the implementation.

### Rules

- **Set `$env:` only for external tool contracts.** If the consumer is our own code, use parameters or module-scoped variables.

- **Read `$env:` only for external system inputs.** CI detection, OS paths, user-set toggles — these are inputs from outside our boundary.

- **Never require an `$env:` variable to be set for a function to work.** Use `[Parameter(Mandatory)]` instead.
  The function signature is the contract, not a hidden environment variable.

- **Never mutate `$env:` mid-execution to communicate between functions.** This is invisible coupling through global state.
  Pass values through parameters and return values.

- **Bootstrap anchors (`$env:RepositoryRoot`) are set once in `importer.ps1` and never modified.**
  They are treated as constants. If you find yourself modifying a bootstrap anchor, the design is wrong.

- **Never store secrets in `$env:`.** Use secret managers, `SecureString`, or secure parameter passing.
  Environment variables are visible to child processes, process inspection tools, and crash dumps.

## Consequences

- Function signatures document their inputs. Callers do not need to set hidden environment variables before calling a function.
- Tests are isolated. No environment variable leaks between test cases, no snapshot/restore ceremony.
- Parallel execution is safe. Module-scoped variables are per-runspace; `$env:` is not.
- Child processes only see variables that were set intentionally for them, not internal state that leaked.
- Debugging is straightforward. State flows through parameters and return values — you can trace it by reading the code.
  Global mutable state requires tracing every possible mutation site in the entire process.
- The codebase has exactly one bootstrap anchor (`$env:RepositoryRoot`), set once, never modified. Everything else flows through function contracts.
