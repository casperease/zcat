# ADR: Conventional folder structure

## Context

A mono-repository without a fixed folder structure degenerates into a naming negotiation.
Every new module, every new config file, every new test suite raises the same questions:
where does this go? What do I call the folder? Do I need to tell something about it?
The answers depend on who you ask, what existed before, and what the last person did.
Over time the layout drifts — one module puts helpers in `internal/`, another in `helpers/`, a third in `util/`.
Tooling cannot program against a layout that changes per module, so configuration files,
path arguments, and environment variables proliferate to bridge the gap.

This platform takes the opposite approach.
The folder structure is fixed, semantic, and the same everywhere.
Tooling hardcodes the well-known names directly. There are no path parameters, no configuration files mapping folder names to meanings,
and no per-module overrides. The folder name IS the contract.

### Why conventional structure matters

**Tooling becomes trivial.** When every module puts private functions in `private/`,
the resolver can hardcode `Join-Path $ModulePath 'private'` and be done.
No parameter, no config, no "discover the helpers folder" heuristic.
`New-DynamicManifest` does not ask where private functions are — it knows, because the structure is a contract.

**Onboarding is instant.** A new contributor opening any module sees the same layout:
root `.ps1` files are public, `private/` is private, `tests/` is tests, `assets/` is everything else.
There is nothing to learn per module. The structure is self-documenting because it is uniform.

**Violations are obvious.** When a module puts tests in `specs/` instead of `tests/`,
the deviation is visible at a glance. More importantly, `Test-Automation` will not find those tests,
because it scans `tests/`. The structure enforces itself — non-conforming content is invisible to tooling.
This is poka-yoke: the wrong thing does not silently work, it visibly does not work.

**Configuration disappears.** Alternative designs require a mapping layer:
a `module.yml` that says `helpers_dir: internal`, or a parameter `-PrivatePath 'helpers'`, or a convention file at the root.
Every mapping layer is a source of truth that must stay in sync with the actual folders.
When the folder name IS the meaning, there is no mapping to maintain, no configuration to drift, no abstraction to debug.

### Why hardcoding paths is a feature

The instinct from application development is that hardcoded paths are a smell.
In application code, that instinct is correct — you want to inject dependencies so you can test against fakes.
In a mono-repo's internal tooling, the calculus is different:

- **The paths are not external dependencies.** They are internal conventions under our control.
  Nobody is going to swap in a different `private/` folder the way you swap a database connection.
  The flexibility that injection provides has no consumer.

- **Indirection hides the contract.** If the resolver takes a `$PrivatePath` parameter,
  every caller must know what to pass. The parameter _looks_ like flexibility but in practice every call site passes `'private'`.
  The parameter adds noise without adding capability.

- **Hardcoded names are greppable.** When tooling hardcodes `'private'`, you can search the codebase for `'private'`
  and find every place that depends on that convention. When the name comes from a variable,
  you must trace the variable to its source — which is inevitably a constant defined somewhere else.

- **The convention is the documentation.** `Join-Path $ModulePath 'tests'` is self-evident.
  `Join-Path $ModulePath $testFolderName` requires you to find where `$testFolderName` is defined
  and confirm it is `'tests'`.

The existing codebase already does this consistently:
`New-DynamicManifest` hardcodes `'private'`, `Test-Automation` hardcodes `'tests'`,
`Import-AllModules` filters on `'^\.'`, `Install-VendorModule` hardcodes `'automation/.vendor'`,
and `importer.ps1` hardcodes `'.resolver'` and `'.vendor'`.
This ADR codifies that pattern as intentional.

### Three levels of structure

The repository has three nested levels of conventional structure, each with its own rules:

1. **Repository root** — top-level directories that separate concerns (automation, docs, output, config, CI).
2. **`automation/`** — the module system root, where dot-prefix separates infrastructure from modules.
3. **Module internals** — the layout inside each module, where folder names determine function visibility and content semantics.

Each level is defined below in the Decision section.

## Decision

The repository uses a fixed, semantic folder layout at three levels.
Tooling programs directly against these well-known paths. Folder names are contracts, not suggestions.

### Level 1: Repository root

| Directory     | Meaning                                                                                         | Programmed against by                                           |
| ------------- | ----------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `automation/` | Module system root — all PowerShell modules and infrastructure                                  | `importer.ps1`, `Test-Automation`, `Install-VendorModule`       |
| `docs/`       | Documentation; contains `automation/adr/` for decision records                                  | Human consumption; ADR file naming convention                   |
| `out/`        | All output files (gitignored) — see [dedicated-output-directory](dedicated-output-directory.md) | Output functions, CI artifacts, cleanup scripts                 |
| `.github/`    | GitHub workflows, actions, templates                                                            | GitHub Actions runner                                           |
| `.vscode/`    | Editor settings, tasks, launch configs                                                          | VS Code                                                         |

`automation/` is the only directory that the module system interacts with.
The others exist for clear separation of concerns at the repo level.
Adding a new top-level directory is a conscious architectural decision, not a casual act.

### Level 2: `automation/` — modules vs. infrastructure

| Convention             | Meaning                                         | Examples                                     |
| ---------------------- | ----------------------------------------------- | -------------------------------------------- |
| Dot-prefixed directory | Infrastructure — invisible to module discovery  | `.resolver/`, `.vendor/`, `.scriptanalyzer/` |
| Non-dot directory      | Module — auto-discovered by `Import-AllModules` | `Zcap.Base/`, `Zcap.Tools/`, `Zcap.Meta/`    |

`Import-AllModules` filters with `$_.Name -notmatch '^\.'`.
This is the entire module discovery mechanism: if the folder name starts with a dot, it is infrastructure; otherwise, it is a module.
No registration, no manifest, no list of module names.

**Why dot-prefix:** The dot-prefix convention is borrowed from Unix (dotfiles are hidden by default) and from this repository's own `.github/` and `.vscode/` patterns.
It communicates "infrastructure, not content" at a glance.
It also sorts infrastructure to the top of directory listings, visually separating it from modules.

### Level 3: Module internals

Every module directory follows the same internal layout:

| Directory/Pattern | Meaning                                               | Programmed against by                               |
| ----------------- | ----------------------------------------------------- | --------------------------------------------------- |
| `*.ps1` (root)    | Public exported functions — file name = function name | `New-DynamicManifest` (derives `FunctionsToExport`) |
| `private/`        | Private helper functions — loaded, not exported       | `New-DynamicManifest` (scans for `NestedModules`)   |
| `tests/`          | Pester test files (`*.Tests.ps1`)                     | `Test-Automation` (discovers test paths)            |
| `assets/`         | All non-function, non-test files the module needs     | Module functions via `$PSScriptRoot`                |

**`private/`** contains `.ps1` files that follow the same one-function-per-file convention as root files.
They are loaded into the module's session state via `NestedModules` but excluded from `FunctionsToExport`.
The folder name `private/` means "non-exported" everywhere, in every module, without exception.

**`private/_ModuleInit.ps1`** is a special convention: if this file exists, the resolver places it first in `NestedModules`
so it runs at module import time, before any function definition. Use it for loading C# types (`Add-Type`),
module-scoped caches, or stale dependency detection. The underscore prefix signals "not a function file" — it is
excluded from Verb-Noun naming and one-function-per-file checks. At most one per module.

**`tests/`** contains `*.Tests.ps1` files. `Test-Automation` scans `Join-Path $moduleDir 'tests'` for every module.
Tests go here and nowhere else. A test file outside `tests/` will not be discovered.

**`assets/`** is for everything that is not a function or a test: configuration (YAML, data files),
vendored scripts, templates, JSON schemas, reference data, embedded resources.
The resolver does not scan this folder. `New-DynamicManifest` does not look here.
`Test-Automation` does not look here. The one-function-per-file validator does not look here.
Module functions reference assets via `$PSScriptRoot` (e.g., `Join-Path $PSScriptRoot 'assets/config/tools.yml'`
or `Join-Path $PSScriptRoot '../assets/config/tools.yml'` from `private/`).
Module authors may create subdirectories inside `assets/` to organize content
(e.g., `assets/config/` for YAML files) — the internal structure is freeform.

Not every module needs every folder. A module with no private helpers has no `private/`.
A module with no assets has no `assets/`. The convention defines what the name means when the folder exists,
not that every folder must exist.

### Rules

- **Folder names are fixed.** Private helpers go in `private/`, not `internal/`, `helpers/`, or `util/`.
  Tests go in `tests/`, not `test/`, `spec/`, or `__tests__/`.
  Assets go in `assets/`, not `resources/`, `data/`, `static/`, `config/`, or `scripts/`.
  The name is the contract. Using a different name means tooling will not find the content.

- **Tooling hardcodes the conventional names.** Functions that interact with the folder structure use literal strings,
  not parameters or configuration. `Join-Path $ModulePath 'private'`, not `Join-Path $ModulePath $privateFolderName`.
  This is intentional — see the rationale above.

- **No module-level override of conventions.** A module cannot opt out of the structure or rename a conventional folder.
  If `private/` means "non-exported" in one module and something different in another,
  the convention is broken and tooling cannot rely on it.

- **Dot-prefix = infrastructure, always.** Any directory under `automation/` that starts with `.` is excluded from module discovery.
  This rule is enforced by `Import-AllModules` and must not be overridden per-directory.

- **New module-level folders require an ADR amendment.** Adding a new well-known folder name
  (beyond `private/`, `tests/`, `assets/`) is a structural change.
  It changes the contract that all tooling programs against.
  It requires updating this ADR and potentially updating the resolver, test runner, or both.

- **Unknown folders are ignored, not errors.** If a module contains a folder that is not one of the conventional names,
  the resolver and test runner ignore it. This is permissive by design —
  modules can have non-standard internal structure for things the platform does not need to know about.
  But the module cannot expect tooling to interact with it.

### Violation patterns

| Pattern                                                      | Problem                                                                                              | Fix                                                |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| Private helpers in `internal/`, `helpers/`, or `util/`       | Resolver does not scan these — functions are invisible                                               | Rename to `private/`                               |
| Tests in `test/`, `spec/`, or the module root                | Test runner does not find them — they never execute                                                  | Move to `tests/` with `*.Tests.ps1` naming         |
| Config in the module root alongside `.ps1` files             | Config files could collide with function naming; unclear boundaries                                  | Move to `assets/`                                  |
| Standalone scripts in the module root                        | Resolver treats them as public functions                                                             | Move to `assets/`                                  |
| Using `config/` or `scripts/` as module subdirectories       | Not a conventional folder — tooling ignores them, convention test fails                              | Move contents to `assets/`                         |
| A non-dot folder under `automation/` that is not a module    | `Import-AllModules` discovers it and tries to build a manifest                                       | Dot-prefix it (infrastructure) or make it a module |
| A dot-prefixed module that should be discovered              | `Import-AllModules` skips it — module is invisible                                                   | Remove the dot prefix                              |
| Passing `-PrivatePath` or similar parameters to the resolver | Adds indirection; the path is always `'private'`                                                     | Hardcode the name; remove the parameter            |
| A `module.yml` mapping folder names to meanings              | Second source of truth that drifts from the actual structure                                         | Remove the mapping; use the convention directly    |
| Putting output files in `assets/`                            | Mixes transient output with source — see [dedicated-output-directory](dedicated-output-directory.md) | Write to `out/`                                    |

### How this is enforced

- **`New-DynamicManifest`** — hardcodes `private/` when scanning for non-exported functions.
  Files not in `private/` or the module root are not included in the manifest.
  A file in `helpers/` is structurally invisible.

- **`Import-AllModules`** — hardcodes the dot-prefix filter (`$_.Name -notmatch '^\.'`).
  Dot-prefixed folders are infrastructure. Non-dot folders are modules. No configuration.

- **`Test-Automation`** — hardcodes `tests/` when discovering test paths.
  Test files outside `tests/` are never executed.

- **`Test-Automation.Tests.ps1`** — validates that every `.ps1` file in a module follows the one-function-per-file convention.
  It scans only the module root and `private/` — files in `assets/` or other folders are not subject to this validation.

- **`importer.ps1`** — hardcodes `automation/`, `.resolver/`, and `.vendor/`.
  These are the bootstrapping paths. They do not come from configuration.

- **Code review.** Structural conventions that tooling cannot enforce (e.g., "this YAML file belongs in `config/`, not the module root")
  are caught in review. The uniform structure makes deviations visually obvious.

## Consequences

- The folder structure is self-documenting. Opening any module reveals the same layout.
  `private/` is private, `tests/` is tests, `assets/` is everything else — no per-module learning curve.
- Tooling is simple and stable. The resolver, test runner, and importer have no configuration for folder names.
  They hardcode the names, and the names do not change.
- New modules are created by copying the folder layout. There is no registration,
  no configuration file to update, no "folder structure" section in a setup guide.
  The layout is the same everywhere because the names are the same everywhere.
- Adding a new conventional folder is a deliberate, documented decision.
  It changes the contract, so it goes through an ADR amendment.
- Non-conforming content is structurally invisible, not an error.
  A module with helpers in `internal/` does not crash the resolver — it just has no private functions.
  This is poka-yoke: the wrong name does not cause a confusing failure,
  it causes a predictable absence that is easy to diagnose.
- The tradeoff is rigidity. You cannot call the test folder `spec/` because you prefer RSpec conventions.
  You cannot call the private folder `internal/` because Go uses that name.
  The platform's consistency is worth more than individual naming preferences.
