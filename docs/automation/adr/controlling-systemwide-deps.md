# ADR: Controlling system-wide dependencies

## Context

Automation code depends on tools installed at the OS level — Python, dotnet, Poetry, Azure CLI, git.
These are not PowerShell modules that can be vendored into the repo. They are binaries managed by platform package managers (winget, brew, apt-get) and installed system-wide.

This creates the hardest reproducibility problem in automation: "works on my machine" caused by different tool versions, missing tools,
or tools installed in unexpected locations.

Containers solve this well — pin a base image, install tools at build time, and every execution is identical. When a container runtime is available,
that is the right approach.

But the platform must also work on machines where Docker is not available. The automation cannot require a container runtime as a prerequisite.

### How we control system-wide dependencies

#### 1. Lock versions in configuration

Every tool has a locked version in `config/tools.yml`:

```yaml
Python:
  Version: "3.11"
  Command: python
  WingetId: "Python.Python.{0}"
  BrewFormula: "python@{0}"
  AptPackage: "python{0}"
  VersionCommand: "python --version"
  VersionPattern: "^Python (?<ver>.+)$"
```

The config is the source of truth. Functions read it via `Get-ToolConfig`. Version changes are pull requests, not ad-hoc installs.

#### 2. Platform-aware installers

Each tool has an `Install-*` function that delegates to the platform's native package manager:

- **Windows:** winget
- **macOS:** brew
- **Linux:** apt-get

The installer is idempotent — if the tool is already installed, it returns immediately (see [idempotent-state-functions](idempotent-state-functions.md)).

#### 3. Assert at runtime

Every `Invoke-*` wrapper asserts the tool is present and at the correct version before executing:

```powershell
Assert-Tool 'Python'   # is it on PATH? does the version match the lock?
```

`Assert-Tool` looks up the command name from config, checks `DependsOn` first, then calls `Assert-Command` and `Assert-ToolVersion`.
If a dependency is missing, the error names the root cause: "Poetry requires Python (python) — run Install-Python."
If the tool itself is missing or at the wrong version, the error says so directly.

Version checks are cached per session — the first `Invoke-Python` call validates, subsequent calls skip the check.

#### 3b. Declare tool dependencies in config

Some tools depend on other tools — Poetry and Azure CLI require Python because they are installed and managed via pip.
These dependencies are declared in `config/tools.yml`:

```yaml
Poetry:
  DependsOn: Python
  PipPackage: poetry
```

`Assert-Tool` checks the dependency before checking the tool itself, so errors name the root cause rather than the symptom.
Pip-based tools share install and uninstall logic through `Install-PipTool` and `Uninstall-PipTool`,
which parallel `Install-Tool` and `Uninstall-Tool` for platform package managers.

#### 4. Orchestrate with Install-WorkstationTools

A single function provisions the entire local development environment:

```powershell
function Install-WorkstationTools {
    Install-Python
    Install-Poetry
    Install-Dotnet
    # ... more tools
}
```

This is idempotent. Run it after every pull, on every new workstation, or on a schedule. It converges the environment to the desired state defined in config.

#### 5. CI uses the same functions

CI pipelines call the same `Install-*` functions that developers use locally. There is no separate "CI setup script" that drifts from the local setup.
If a tool works locally, it works in CI — same config, same installer, same assertions.

```yaml
- name: Setup
  shell: pwsh
  run: |
    . ./importer.ps1
    Install-WorkstationTools
```

## Decision

System-wide tool dependencies are version-locked in configuration, installed via platform-native package managers, and asserted at runtime before every use.
The platform works without a container runtime on Windows, macOS, and Linux.

### Rules

- **Lock every tool version in `config/tools.yml`.** No tool is installed at "latest." Every version is explicit and reviewable.

- **One `Install-*` / `Invoke-*` / `Uninstall-*` triad per tool.** The installer handles platform differences. The invoker asserts version and presence. The uninstaller cleans up.

- **Assert before every invocation.** `Assert-Tool` runs before every external tool call. It checks `DependsOn`, `Assert-Command`, and `Assert-ToolVersion`.
  Missing or wrong-version tools fail immediately with a clear message.

- **Declare tool dependencies in config.** If a tool requires another tool at runtime or install time, add `DependsOn` to its entry in `tools.yml`. `Assert-Tool` checks dependencies automatically.

- **CI and local use the same code path.** No separate CI setup scripts. The same `Install-WorkstationTools` that runs on a developer workstation runs in the pipeline.

- **Do not assume tools are pre-installed.** Even on CI runners with pre-installed tools, assert the version. Runner images change without notice.

## Consequences

- Tool versions are consistent across all developers and CI environments.
- Version upgrades are pull requests with a one-line config change.
- New developers run `Install-WorkstationTools` once and have a working environment.
- CI pipelines are self-provisioning — they do not depend on runner image contents.
- The platform works on bare metal, VMs, workstations, and CI runners without requiring Docker.
