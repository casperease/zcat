# ADR: Never depend on `$PWD`

## Context

PowerShell scripts often assume they are run from a specific directory — typically the repository root.
This works when the author runs the script manually but breaks the moment someone calls the function from a different working directory,
a scheduled task, a CI pipeline, or a nested script that changed location earlier.

Functions that use relative paths like `./config/meta.yml`, or shell out to tools sensitive to the current directory (git, dotnet, poetry),
will silently operate on the wrong files or fail with confusing errors when `$PWD` is not what the author expected.

### What we tried

1. **Documenting "run from repo root"** — people forget, CI configs drift, and nested calls break the assumption silently.

2. **`Set-Location` at the top of scripts** — changes `$PWD` globally, which affects every function called afterward and is not safe in concurrent or nested scenarios.

## Decision

All functions must work correctly regardless of the caller's `$PWD`.

### Rules

- **Never use relative paths that depend on `$PWD`.** Use `$PSScriptRoot`, `$env:RepositoryRoot`, or `Join-Path` from a known anchor.

- **When a tool requires a specific working directory**, use `Push-Location` / `Pop-Location` in a `try`/`finally` block to temporarily change directory and guarantee restoration:

  ```powershell
  Push-Location $targetPath
  try {
      Invoke-CliCommand "dotnet build"
  }
  finally {
      Pop-Location
  }
  ```

- **Never call `Set-Location` without restoring it.** Bare `Set-Location` (or `cd`) changes `$PWD` for the rest of the session. If you must change directory, use `Push-Location` / `Pop-Location` so the caller's location is preserved.

- **Tests must not assume `$PWD`.** Test setup should use absolute paths derived from `$env:RepositoryRoot` or `$PSScriptRoot`.

### How this is enforced

- **Custom PSScriptAnalyzer rule `Measure-NeverDependOnPwd`** (`automation/.scriptanalyzer/NeverDependOnPwd.psm1`) — warns on bare `Set-Location`/`cd` calls and relative paths that depend on `$PWD`. Runs as part of the L2 test suite via `Test-ScriptAnalyzer.Tests.ps1`.

## Consequences

- Functions can be composed freely — calling `Invoke-Poetry` from inside `Install-Poetry` works regardless of where the user's shell is sitting.
- CI pipelines and scheduled tasks work without a `cd` preamble.
- `$PSScriptRoot` and `$env:RepositoryRoot` are the standard anchors for locating files. `$PSScriptRoot` gives the directory of the current script file; `$env:RepositoryRoot` gives the repository root set by `importer.ps1`.
- Tools that need a working directory (git, dotnet, poetry) get it via `Push-Location`/`Pop-Location`, never by assuming `$PWD` is already correct.
