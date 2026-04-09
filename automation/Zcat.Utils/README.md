# Zcat.Utils

Utility module — CLI execution, formatted output, repository navigation, and dependency analysis.

## What's in here

**CLI execution** — `Invoke-Executable` wraps external tool invocation with exit code handling, output capture (`-PassThru`), dry-run support (`-DryRun`), and automatic logging of the exact command before execution.

**Repository navigation** — `Get-RepositoryRoot`, `Get-RepositoryFile`, `Get-RepositoryFolder` resolve paths relative to `$env:RepositoryRoot` so functions never depend on `$PWD`.

**Deep clone** — `Copy-Object` recursively clones hashtables, ordered dictionaries, PSCustomObjects, and arrays without BinaryFormatter. Emits a warning on PSCustomObject (note properties only) — suppress with `-AcceptWarnings`.

**Formatted output** — `Write-Message`, `Write-Object`, `Write-Header`, `Write-Exception`, and `Write-InformationColored`. Consistent console output with caller prefixes, opt-in timestamps (`$env:ZCAT_MESSAGE_TIMESTAMPS`), and proper color usage.

**Dependency analysis** — `Get-FunctionDependency` and `Get-ModuleDependency` use AST parsing to map function-to-function and module-to-module call graphs across the codebase.

## Design

Everything in this module has zero external dependencies beyond Zcat.Assert — it only uses built-in PowerShell, .NET, and the assertion library.
