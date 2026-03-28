# ADR: Error handling — fail immediately, no warnings

## Status

Accepted

## Context

PowerShell has a complex error handling model: terminating errors,
non-terminating errors, `$ErrorActionPreference`, `$WarningPreference`,
`-ErrorAction` per call, error records, warning records, and multiple
output streams. Most PowerShell code uses a subset of this incorrectly,
leading to errors that are swallowed, warnings that nobody reads, and
failures that surface far from their origin.

### The two-state model

We simplify this to two states:

1. **Everything is fine.** Execution continues. Output goes through
   `Write-Message`, `Write-Information` and `Write-Verbose`.
2. **Something is wrong.** Execution stops immediately via `throw` or
   `Assert-*`. The error propagates to the caller with a clear message.

There is no middle ground. No warnings, no non-terminating errors, no
"something went wrong but let's keep going." Code that continues after
a problem is code that operates on corrupted state.

### Why no warnings

`Write-Warning` is PowerShell's way of saying "this might be a problem
but I will continue anyway." In practice this means:

- **Nobody reads them.** Warnings scroll past in interactive use and
  get buried in CI logs. If the script succeeded, nobody goes back to
  check for yellow text.

- **They hide bugs.** A warning that fires on every run becomes invisible
  background noise. The one time it signals a real problem, it is lost
  among the habitual warnings the team has learned to ignore.

- **They create ambiguity.** Did the script succeed or not? It produced
  output and returned exit code 0, but there were warnings. Should the
  pipeline proceed? Should the user investigate? Nobody knows, so
  everybody ignores it.

The importer sets `$WarningPreference = 'Stop'`, which turns every
`Write-Warning` call into a terminating error. This is deliberate — if
a condition is wrong enough to warn about, it is wrong enough to stop.

### Why no Write-Error

`Write-Error` creates a non-terminating error record. Whether it actually
stops execution depends on `$ErrorActionPreference`, which varies by
context. This ambiguity is the root cause of most PowerShell error
handling bugs: the author wrote `Write-Error` expecting it to stop, but
the caller's preference was `Continue`, so execution continued with bad
state.

`throw` is unambiguous. It always terminates. The importer also sets
`$ErrorActionPreference = 'Stop'` so that cmdlet errors (which use the
non-terminating error mechanism internally) also terminate. Between
`throw` and `$ErrorActionPreference = 'Stop'`, every error is fatal.

### The Assert-* pattern

Instead of `if ($bad) { throw "message" }` scattered through the code,
use the `Assert-*` library:

```powershell
Assert-Command python                    # throws: "'python' is not installed"
Assert-ToolVersion -Tool 'Python'        # throws: "Python version mismatch: expected 3.11.x, found 3.10.2"
Assert-PathExist $configPath             # throws: "Path does not exist: /app/config.yml"
Assert-NotNullOrWhitespace $name         # throws: "Assertion failed: value was null or whitespace — Deploy.ps1, line 42"
```

Each assertion produces a structured, self-contained error message. The
message names the specific assumption that was violated. No generic
"an error occurred" — the user knows exactly what is wrong from the
error message alone.

### Error recovery

When a function encounters a condition it cannot handle, it throws. The
caller decides what to do:

```powershell
# Caller handles the error — the function does not
try {
    Invoke-Poetry 'install'
}
catch {
    Write-Message "Poetry install failed, falling back to manual setup"
    Install-ManualDependencies
}
```

Functions never catch-and-continue internally. If `Invoke-Poetry` fails,
it throws. Whether to retry, fall back, or abort is the caller's
decision (see [single-responsibility-functions](single-responsibility-functions.md)).

### Interactive error diagnostics

In interactive mode, the importer installs a prompt hook that calls
`Write-Exception` after every failed command. This provides a full stack
trace with file names and line numbers — far more useful than
PowerShell's default error display. In scripts, authors add
`trap { Write-Exception $_; break }` after the importer for the same
effect.

### The -AllowWarnings escape hatch

The importer accepts `-AllowWarnings` to set `$WarningPreference` back
to `Continue`. This exists for edge cases where third-party tools emit
warnings through PowerShell's warning stream that cannot be suppressed
at the source. It should be rare — if you find yourself using it, first
check whether the warning can be fixed or the call can use
`-WarningAction SilentlyContinue` on the specific cmdlet.

## Decision

All errors are terminating. All warnings are terminating. Functions use
`throw` and `Assert-*` for failures, never `Write-Error` or
`Write-Warning`. Error recovery is the caller's responsibility.

### Rules

- **Set `$ErrorActionPreference = 'Stop'` globally.** The importer does
  this. Never change it inside functions.

- **Set `$WarningPreference = 'Stop'` globally.** The importer does this.
  If a specific cmdlet emits unavoidable warnings, suppress them with
  `-WarningAction SilentlyContinue` on that call only.

- **Use `throw` for errors, not `Write-Error`.** `throw` is unambiguous.
  `Write-Error` depends on the caller's preference and may not stop
  execution.

- **Use `Assert-*` for precondition checks.** The assertion library
  provides consistent, self-contained error messages. Do not inline
  `if (-not $x) { throw }` when an `Assert-*` function exists.

- **Never use `Write-Warning`.** If something is wrong, throw. If it is
  informational, use `Write-Message` or `Write-Verbose`.

- **Never catch-and-continue inside functions.** Functions throw on
  failure. The caller decides whether to catch, retry, or abort.

- **Use `trap { Write-Exception $_; break }` in scripts.** This gives
  full stack traces for unhandled errors, matching the interactive
  prompt hook behavior.

### How this is enforced

- **`importer.ps1`** — sets `$ErrorActionPreference = 'Stop'` and
  `$WarningPreference = 'Stop'` globally.
- **`Set-StrictMode -Version Latest`** — catches uninitialized variables
  and other common mistakes at runtime.
- **Interactive prompt hook** — `Write-Exception` fires automatically
  after every failed command, providing full diagnostics.

## Consequences

- Every error stops execution immediately. No silent failures, no
  corrupted state from continuing after errors.
- Error messages are self-contained — the user can diagnose the problem
  from the message alone.
- CI pipelines fail fast and fail clearly. No ambiguous "succeeded with
  warnings" status.
- The codebase has exactly two output paths: success (information stream)
  and failure (throw). No third path for "maybe wrong."
- Third-party cmdlets that emit warnings will terminate under the default
  settings. Handle these with `-WarningAction SilentlyContinue` on the
  specific call, or use `-AllowWarnings` on the importer as a last resort.
