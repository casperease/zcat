# pwsh

PowerShell 7.4+ module system with zero-ceremony module authoring.

## Project structure

- `importer.ps1` — root script that imports all modules
- `automation/` — module folders containing `.ps1` function files
- `automation/.resolver/Resolver.psm1` — bootstrapping module (loaded first, removed after import)
- `automation/.vendor/` — third-party modules (checked in)
- `docs/automation/` — ADRs, FAQ, and other automation docs

## Rules

- **One function per file** (`Verb-Noun.ps1`): `Get-Foo.ps1` must contain exactly `function Get-Foo`
- **Folder = module**: A module is a folder under `automation/` containing `.ps1` files
- **Public/private by location**: `.ps1` files at the module root are PUBLIC (exported). `.ps1` files in `private/` are PRIVATE (loaded but not exported). Private functions are available to public functions via shared module scope (`.ps1` in `NestedModules`).
- `importer.ps1` handles loading all modules
- **README.md must be generic**: do not hardcode module names, function lists, or other content that changes as modules are added/removed. Use placeholders and describe patterns, not instances.
- **No mutating git operations**: Never run git add, commit, push, reset, checkout, rebase, merge, or other state-changing git commands unless the user explicitly asks. Read-only commands (status, log, diff, blame) are fine.
