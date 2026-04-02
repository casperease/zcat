# zcap — Zero Ceremony Automation Platform

PowerShell 7.4+ module system for monorepos. Drop a file, get a function — no manifests, no installers, no configuration.

Copy `automation/` and `importer.ps1` into your repo. Everything is self-contained: vendored dependencies, no network calls, no global state.

[![CI](../../actions/workflows/ci.yml/badge.svg)](../../actions/workflows/ci.yml)

---

## Quick start

| Context                 | Command                            |
| ----------------------- | ---------------------------------- |
| Interactive terminal    | `.\importer.ps1`                   |
| Inside a script         | `. ./importer.ps1`                 |
| Debug (expose privates) | `. ./importer.ps1 -ExportPrivates` |

Every function from every module is available after import. Load time: **~0.5s**. Use `-DiagnoseLoadTime` to see per-step timings.

---

## Using in practice

### In a script

```powershell
#!/usr/bin/env pwsh
. ./importer.ps1
trap { Write-Exception $_; break }

# All functions from all modules are available here.
Assert-Command git
Write-Message 'Ready to go'
```

Dot-source the importer, add the `trap` line for automatic stack traces on errors, then write your logic. Nothing else to set up.

### In CI/CD

```yaml
steps:
    - name: Run automation
      shell: pwsh
      run: |
          . ./importer.ps1
          Test-Automation
```

- Works on Linux, Windows, and macOS — CI runs on all three
- No install step needed — all dependencies are vendored
- `$ErrorActionPreference = 'Stop'` is set globally — errors propagate as non-zero exit codes automatically
- No network calls at import time — safe behind corporate proxies and in air-gapped environments

### Error handling

The importer sets `$ErrorActionPreference` and `$WarningPreference` to `Stop`. Errors and warnings are both fatal — bad state cannot silently propagate.

- **Interactive sessions**: the prompt hook automatically displays stack traces when an error occurs
- **Scripts**: add `trap { Write-Exception $_; break }` after the importer line

Use `Assert-*` functions for precondition checks. Each one throws with a self-contained error message naming the exact assumption that was violated:

```powershell
Assert-Command terraform
Assert-PathExist $configPath
Assert-NotNullOrWhitespace $subscriptionId -ErrorText 'No subscription ID configured'
```

---

## Project layout

```text
importer.ps1                       entry point
automation/
  .resolver/                       manifest generator (bootstraps, then unloads)
  .scriptanalyzer/                 custom PSScriptAnalyzer rules
  .vendor/                         third-party modules (checked in, no network)
  <Module>/
    Verb-Noun.ps1                  public function (one per file)
    private/
      Verb-Noun.ps1                private function (shared module scope)
      _ModuleInit.ps1              module load-time code (optional)
    assets/                        config files, templates, scripts
    tests/
      Verb-Noun.Tests.ps1          Pester tests (one per function)
docs/automation/adr/               architecture decision records
.github/workflows/ci.yml           CI (Linux + Windows + macOS)
```

---

## Conventions

| Rule                        | Detail                                                                     |
| --------------------------- | -------------------------------------------------------------------------- |
| One function per file       | `Verb-Noun.ps1` contains exactly `function Verb-Noun`                      |
| Folder = module             | Each non-dot directory under `automation/` is a module                     |
| Public by default           | `.ps1` at module root = exported                                           |
| Private by location         | `.ps1` in `private/` = loaded, not exported                                |
| Dot-prefix = infrastructure | `.resolver/`, `.vendor/`, `.scriptanalyzer/` are not modules               |
| K&R braces                  | Opening brace on same line (enforced by PSScriptAnalyzer)                  |
| Approved verbs only         | Use verbs from `Get-Verb` (enforced by PSScriptAnalyzer)                   |
| snake_case in YAML          | All config property keys use `snake_case` (enforced by `Assert-YmlNaming`) |

---

## Extending

### Add a function

Create the file, re-run the importer. The resolver discovers it automatically — no manifest to update, no export list to maintain.

```powershell
# automation/<Module>/Verb-Noun.ps1
function Verb-Noun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )
    # ...
}
```

### Add a private helper

Create `Verb-Noun.ps1` in `private/`. It loads into the module's session state but is not exported. Callable from any function in the same module.

### Add a module

Create a folder under `automation/`. Add `.ps1` files. The folder name becomes the module name. No registration, no configuration.

### Add module initialization code

Create `private/_ModuleInit.ps1`. It runs at import time before any function definitions — use it for `Add-Type`, module-scoped caches, or early validation. At most one per module.

---

## Tool management

CLI tools follow the `Install-` / `Invoke-` / `Uninstall-` pattern. Versions are locked in a YAML config file.

| Function pattern   | Behavior                                                                                              |
| ------------------ | ----------------------------------------------------------------------------------------------------- |
| `Install-<Tool>`   | Installs the locked version. Idempotent — skips if already correct. `-Force` replaces wrong versions. |
| `Invoke-<Tool>`    | Asserts the installed version matches config before execution (cached per session).                   |
| `Uninstall-<Tool>` | Removes the managed installation.                                                                     |

Platform-specific package managers are selected automatically: winget on Windows, Homebrew on macOS, apt on Linux, pip as a cross-platform fallback. Tools prefer user-space installation to avoid admin requirements.

---

## Testing

```powershell
.\importer.ps1
Test-Automation                      # L0 + L1 (fast, default)
Test-Automation -Level 2             # include L2 integration tests
Test-Automation -Output Detailed     # verbose output
```

| Level | Time limit | Scope                            |
| ----- | ---------- | -------------------------------- |
| L0    | < 400ms    | Pure logic, no I/O               |
| L1    | < 2s       | Unit tests, may touch disk       |
| L2    | < 120s     | Integration, may spawn processes |

Convention tests run automatically and verify naming, one-function-per-file, and PSScriptAnalyzer compliance across all modules.

---

## How it works

1. `importer.ps1` rebuilds `$env:PSModulePath` from scratch (strips network paths for fast startup) and loads the resolver
2. Vendored modules in `.vendor/` load first — Pester and PSScriptAnalyzer are lazy-loaded for speed
3. The resolver scans each module folder, generates a `.psd1` manifest from the filesystem, and imports it globally
4. The resolver unloads itself — it has served its purpose
5. Interactive sessions get a prompt hook with automatic error diagnostics and load timing

The filesystem is the single source of truth. There are no hand-maintained manifests, no export lists, no registration steps.

---

## Vendored dependencies

Third-party modules in `.vendor/` are committed to the repo. No network calls at runtime, no version resolution, no gallery access required.

```powershell
Install-VendorModule <ModuleName>
Install-VendorModule <ModuleName> -RequiredVersion <Version>
```

---

## Design

[**Zero ceremony, hard to fail.**](../docs/automation/adr/zero-ceremony-poka-yoke.md) Every design choice is evaluated against two questions: _Does this add ceremony?_ and _Can the author get this wrong?_

See the [architecture decision records](../docs/automation/adr/) for the full set of design rationale covering error handling, folder conventions, vendor strategy, cross-platform support, and enterprise environments.
