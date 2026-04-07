# ADR: Automatic variable pitfalls

## Context

PowerShell defines dozens of [automatic variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables) —
variables set and updated by the engine implicitly.
Some are stable (`$PSScriptRoot`, `$PSVersionTable`, `$true`/`$false`/`$null`).
Others are **implicit mutable state** that the engine overwrites silently after every statement, pipeline stage, or regex match.

The core problem: **automatic variables are only valid at the exact point they are set.**
One statement later they may reflect a completely different operation.
Code that reads them "at a distance" — separated from the operation that set them by other statements, function calls, or control flow — is reading stale state.

### The general principle

> If an automatic variable is set implicitly by the engine, treat it like a register value in assembly:
> **read it immediately or lose it.** If you need the value later, capture it in a named local on the very next line.
> Better yet, use a wrapper that encapsulates the read-and-reset cycle so callers never touch the variable directly.

## Decision

Automatic variables that carry implicit state must be handled according to the rules below.
Variables not listed here (e.g., `$PSScriptRoot`, `$true`, `$null`, `$PSVersionTable`) are stable and safe to use freely.

---

### `$?` — never use

`$?` contains the success/failure status of the **last statement**. Every statement overwrites it — including the statement that tries to read it.

```powershell
# BROKEN — $? reflects the assignment, not Get-Item
Get-Item 'C:\nonexistent'
$ok = $?        # $ok is True — the assignment "$ok = $?" succeeded
```

```powershell
# BROKEN — the Assert-Success anti-pattern
Invoke-Something          # fails
Do-SomethingElse          # succeeds
Assert-Success            # checks $? — sees True from Do-SomethingElse, not the failure
```

There is no reliable way to use `$?` in general-purpose code.

**What to do instead:**

- For **cmdlets and functions**: `-ErrorAction Stop` (set globally by the importer) so failures throw. Catch with `try`/`catch`. See [error-handling](error-handling.md).
- For **native executables**: use `$LASTEXITCODE` (see below) or `Invoke-CliCommand` which handles the entire cycle.

**Enforced by:** PSScriptAnalyzer custom rule `Measure-NoAutomaticVariableMisuse` (severity: Error).

---

### `$LASTEXITCODE` — use immediately, then reset

`$LASTEXITCODE` holds the exit code of the last native executable. Unlike `$?`, it **persists** until the next native executable runs.
This means a stale `$LASTEXITCODE` from a previous call can leak across function boundaries and appear to belong to a later operation.

**The safe pattern — `Invoke-CliCommand`:**

```powershell
# Invoke-CliCommand encapsulates the entire cycle:
#   1. Reset-LastExitCode          ← clean slate
#   2. Invoke-Expression $Command  ← run the native call
#   3. Assert-LastExitCodeWasZero  ← check immediately
#   4. Reset-LastExitCode          ← clean slate for next caller

Invoke-CliCommand 'az account show --output json'
# At this point $LASTEXITCODE is cleared — no stale state can leak
```

**When you need the exit code with `-NoAssert`** (e.g., for expected non-zero exits):

`Invoke-CliCommand -PassThru` returns a `Zcat.CliResult` object with an `ExitCode` property.
This eliminates the need to touch `$LASTEXITCODE` directly:

```powershell
# Correct — use the result object's ExitCode property
$result = Invoke-CliCommand 'az account show --output json' -PassThru -NoAssert -Silent
if ($result.ExitCode -ne 0 -or -not $result.Output) {
    Write-Message 'Not logged in — nothing to do'
    return
}
$account = $result.Output | ConvertFrom-Json
```

**Pipeline trap — cmdlets mask native exit state:**

When a native executable pipes into a cmdlet, the cmdlet becomes the last command in the pipeline.
`$?` reflects the **cmdlet**, not the executable — and if the cmdlet succeeds, the native failure is silently swallowed.

```powershell
# BROKEN — $? reflects ConvertFrom-Json, not az
$myvar = az account show | ConvertFrom-Json
Assert-Success   # passes even when az exited non-zero

# Why it's insidious:
#   1. az fails (exit code 1) but emits an error response as JSON
#   2. ConvertFrom-Json happily parses the error JSON → $? is True
#   3. $myvar now contains an error object, and nobody noticed
#
# Even when az emits nothing, ConvertFrom-Json returns $null
# without error in PS 7.4+ — $? is still True.
```

`$LASTEXITCODE` _is_ still set correctly by the native call, but code that checks `$?` (or an `Assert-Success` that checks `$?`) will never see the failure.

```powershell
# Correct — use Invoke-CliCommand -PassThru, then parse the result
$result = Invoke-CliCommand 'az account show --output json' -PassThru
$myvar = $result.Output | ConvertFrom-Json
```

**Rules:**

- **Always reset before invoking.** Prevents a stale exit code from a prior call from leaking into your check.
- **Always check (or assert) immediately after invoking.** No intervening statements between the native call and the exit code check.
- **Always reset after checking.** Prevents your exit code from leaking to the next caller.
- **Prefer `Invoke-CliCommand`.** It encapsulates all three steps. Only use raw `$LASTEXITCODE` when you need `-NoAssert` for expected failures.

---

### `$Matches` — capture immediately

`$Matches` is overwritten by every `-match` or `-replace` operation. Sequential matches silently clobber previous results.

```powershell
# BROKEN — second -match overwrites $Matches from the first
$line -match 'name=(.+)'
$header -match 'version=(\d+)'
$name = $Matches[1]   # this is the version, not the name
```

```powershell
# Correct — capture immediately after each match
$line -match 'name=(.+)'
$name = $Matches[1]

$header -match 'version=(\d+)'
$version = $Matches[1]
```

**Rule:** If you use `-match`, capture `$Matches` into a named local on the very next line.

---

### `$_` / `$PSItem` — scoped to the current pipeline or catch block

`$_` is set by the pipeline, `ForEach-Object`, `Where-Object`, `catch`, `trap`, and `switch`.
Each of these scopes overwrites `$_` — inner pipelines shadow the outer `$_` silently.

```powershell
# BROKEN — inner ForEach-Object shadows $_
$users | ForEach-Object {
    $_.Roles | ForEach-Object {
        # $_ is now a Role, not a User
        Write-Message "$($_.Name) has role $_"   # $_.Name is Role.Name, not User.Name
    }
}
```

```powershell
# Correct — capture in a named variable before nesting
$users | ForEach-Object {
    $user = $_
    $user.Roles | ForEach-Object {
        Write-Message "$($user.Name) has role $_"
    }
}
```

**Rule:** When nesting pipelines or mixing pipeline with `catch`/`switch`, always capture `$_` in a named local at the top of the outer block.

---

### `$Error` — never use for control flow

`$Error` is a global list that **accumulates every error** across the entire session. It is not scoped to your function or script.

- It contains errors from the importer, from modules loading, from previous commands the user ran interactively.
- `$Error[0]` is only "your" error if nothing else has errored since — which you cannot guarantee.
- `$Error.Clear()` affects the global session state and may break other code that inspects `$Error`.

**What to do instead:** Use `try`/`catch` to handle errors structurally. The caught exception in `catch` is scoped and unambiguous.
See [error-handling](error-handling.md).

**Exception:** The importer's interactive `prompt` function inspects `$global:Error[0]` to display the last error after each command.
This is infrastructure code with a legitimate need to read the global error list in the prompt context.

---

## Summary of rules

| Variable         | Rule                                                            | Alternative                         |
| ---------------- | --------------------------------------------------------------- | ----------------------------------- |
| `$?`             | In general, dont use                                            | `-ErrorAction Stop` + `try`/`catch` |
| `$LASTEXITCODE`  | Reset → invoke → assert → reset (use `Invoke-CliCommand`)       | Direct check only with `-NoAssert`  |
| `$Matches`       | Capture into a named local on the very next line after `-match` | —                                   |
| `$_` / `$PSItem` | Capture into a named local before nesting pipelines             | —                                   |
| `$Error`         | Never use for control flow                                      | `try`/`catch`                       |

## Consequences

- Eliminates the "stale read" class of bugs where automatic variables reflect a different operation than the author intended.
- `Invoke-CliCommand` becomes the standard entry point for native executables — callers never need to think about `$LASTEXITCODE` lifecycle.
- The `$?` ban is enforced statically by PSScriptAnalyzer. Other variables are enforced by code review and this ADR.
- Code that previously relied on `$?` must migrate to the error handling patterns in [error-handling](error-handling.md).
