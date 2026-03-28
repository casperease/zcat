# Zcap.Base

Foundation module — the things PowerShell should have had built in.

## What's in here

**Assertions** — `Assert-True`, `Assert-PathExist`, `Assert-Command`, `Assert-NotNullOrWhitespace`, and others. Fail fast with clear error messages. Each `Assert-*` has a corresponding `Test-*` that returns a boolean.

**CLI execution** — `Invoke-CliCommand` wraps external tool invocation with exit code handling, output capture (`-PassThru`), dry-run support (`-DryRun`), and automatic logging of the exact command before execution.

**Repository navigation** — `Get-RepositoryRoot`, `Get-RepositoryFile`, `Get-RepositoryFolder` resolve paths relative to `$env:RepositoryRoot` so functions never depend on `$PWD`.

**Deep clone** — `Copy-Object` recursively clones hashtables, ordered dictionaries, PSCustomObjects, and arrays without BinaryFormatter. Emits a warning on PSCustomObject (note properties only) — suppress with `-AcceptWarnings`.

**YAML validation** — `Assert-YmlNaming` enforces snake_case on all property keys in parsed YAML structures.

**Formatted output** — `Write-Message`, `Write-Object`, `Write-Header`, `Write-Hashtable`, `Write-Array`, `Write-Exception`, and `Write-InformationColored`. Consistent console output with caller prefixes, opt-in timestamps (`$env:ZCAP_MESSAGE_TIMESTAMPS`), and proper color usage.

**Dependency analysis** — `Get-FunctionDependency` and `Get-ModuleDependency` use AST parsing to map function-to-function and module-to-module call graphs across the codebase.

## Design

Everything in this module has zero external dependencies — it only uses built-in PowerShell and .NET. Other modules depend on Base; Base depends on nothing.
