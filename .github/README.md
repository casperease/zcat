# adp

**Automation toolset for monorepos.** PowerShell 7.4+, zero-ceremony modules, vendored dependencies, fast imports.

Drop the `automation/` folder and `importer.ps1` into the root of any monorepo. No installers, no package managers, no global state — everything is self-contained.

[![CI](../../actions/workflows/ci.yml/badge.svg)](../../actions/workflows/ci.yml)

---

## Get started

```powershell
.\importer.ps1                      # interactive terminal
. ./importer.ps1                    # inside a script (dot-source)
. ./importer.ps1 -ExportPrivates    # debug mode — all private functions visible
```

## Add a function

Drop a `Verb-Noun.ps1` into any module folder. Re-run the importer. Done.

```powershell
# automation/Zcap.Base/Get-Something.ps1
function Get-Something {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )
    # ...
}
```

Private functions go in `private/` — loaded but not exported, callable from the same module.

## Project layout

```text
importer.ps1                       entry point
automation/
  .resolver/                       manifest generator (bootstraps, then unloads)
  .scriptanalyzer/                 custom linting rules
  .vendor/                         third-party modules (checked in, no network)
  <Module>/
    Verb-Noun.ps1                  public function (one per file)
    private/Verb-Noun.ps1          private function (shared module scope)
    config/*.yml                   module configuration
    tests/Verb-Noun.Tests.ps1      Pester tests (one per function)
docs/                              ADRs and design docs
.github/workflows/ci.yml           Linux + Windows CI
```

## Conventions

| Rule                  | Detail                                            |
| --------------------- | ------------------------------------------------- |
| One function per file | `Get-Foo.ps1` contains exactly `function Get-Foo` |
| Folder = module       | Each directory under `automation/` is a module    |
| Public by default     | `.ps1` at module root = exported                  |
| Private by location   | `.ps1` in `private/` = loaded, not exported       |
| K&R braces            | Opening brace on same line (enforced)             |
| Snake case in YAML    | All config property keys use `snake_case`         |
| Approved verbs only   | Use verbs from `Get-Verb` (enforced)              |

## Testing

```powershell
.\importer.ps1
Test-Automation                      # L0 + L1 (fast, default)
Test-Automation -Level 2             # include L2 integration tests
Test-Automation -Output Detailed     # verbose
```

| Level | Time limit | Scope                            |
| ----- | ---------- | -------------------------------- |
| L0    | < 400ms    | Pure logic, no I/O               |
| L1    | < 2s       | Unit tests, may touch disk       |
| L2    | < 120s     | Integration, may spawn processes |

Convention tests verify naming, one-function-per-file, and PSScriptAnalyzer compliance.

## How it works

1. Importer loads the resolver
2. Vendored modules load (Pester + PSScriptAnalyzer are lazy-loaded for speed)
3. Each module folder gets a generated `.psd1` manifest and is imported globally
4. Resolver unloads itself
5. Interactive sessions get a prompt hook with error diagnostics and load timing

Import time: **~0.5s**

## Error handling

`$ErrorActionPreference = 'Stop'` everywhere — fail fast.

- **Interactive**: prompt hook auto-displays stack traces via `Write-Exception`
- **Scripts**: add `trap { Write-Exception $_; break }` after the importer

## Tool management

CLI tools are wrapped with `Install-`/`Invoke-`/`Uninstall-` functions. Versions are locked in YAML config. `Invoke-*` asserts the installed version matches before executing.

## Vendored modules

Third-party modules in `.vendor/` are committed to the repo. No network calls at runtime.

```powershell
Install-VendorModule <ModuleName>
Install-VendorModule <ModuleName> -RequiredVersion <Version>
```

## Design

[**Zero ceremony, hard to fail.**](../docs/automation/adr/zero-ceremony-poka-yoke.md) See the [design docs](../docs/) for ADRs and rationale.
