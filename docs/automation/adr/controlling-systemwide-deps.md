# ADR: Controlling system-wide dependencies

## Context

Automation code depends on tools installed at the OS level — Python,
dotnet, Poetry, Azure CLI, git. These are not PowerShell modules that
can be vendored into the repo. They are binaries managed by platform
package managers (winget, brew, apt-get) and installed system-wide.

This creates the hardest reproducibility problem in automation: "works on
my machine" caused by different tool versions, missing tools, or tools
installed in unexpected locations.

Containers solve this well — pin a base image, install tools at build
time, and every execution is identical. When a container runtime is
available, that is the right approach.

But the platform must also work on machines where Docker is not
available. The automation cannot require a container runtime as a
prerequisite.

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

The config is the source of truth. Functions read it via `Get-ToolConfig`.
Version changes are pull requests, not ad-hoc installs.

#### 2. Platform-aware installers

Each tool has an `Install-*` function that delegates to the platform's
native package manager:

- **Windows:** winget
- **macOS:** brew
- **Linux:** apt-get

The installer is idempotent — if the tool is already installed, it
returns immediately (see [idempotent-state-functions](idempotent-state-functions.md)).

#### 3. Assert at runtime

Every `Invoke-*` wrapper asserts two things before executing:

```powershell
Assert-Command python              # is the tool on PATH?
Assert-ToolVersion -Tool 'Python'  # does the version match the lock?
```

If the tool is missing, the error says so. If the version is wrong, the
error shows expected vs actual. No silent execution with the wrong
version.

Version checks are cached per session — the first `Invoke-Python` call
validates, subsequent calls skip the check.

#### 4. Orchestrate with Install-DevBox

A single function provisions the entire development environment:

```powershell
function Install-DevBox {
    Install-Python
    Install-Poetry
    Install-Dotnet
    # ... more tools
}
```

This is idempotent. Run it after every pull, on every new machine, or
on a schedule. It converges the environment to the desired state defined
in config.

#### 5. CI uses the same functions

CI pipelines call the same `Install-*` functions that developers use
locally. There is no separate "CI setup script" that drifts from the
local setup. If a tool works locally, it works in CI — same config, same
installer, same assertions.

```yaml
- name: Setup
  shell: pwsh
  run: |
    . ./importer.ps1
    Install-DevBox
```

## Decision

System-wide tool dependencies are version-locked in configuration,
installed via platform-native package managers, and asserted at runtime
before every use. The platform works without a container runtime on
Windows, macOS, and Linux.

### Rules

- **Lock every tool version in `config/tools.yml`.** No tool is installed
  at "latest." Every version is explicit and reviewable.

- **One `Install-*` / `Invoke-*` / `Uninstall-*` triad per tool.** The
  installer handles platform differences. The invoker asserts version and
  presence. The uninstaller cleans up.

- **Assert before every invocation.** `Assert-Command` and
  `Assert-ToolVersion` run before every external tool call. Missing or
  wrong-version tools fail immediately with a clear message.

- **CI and local use the same code path.** No separate CI setup scripts.
  The same `Install-DevBox` that runs on a developer laptop runs in the
  pipeline.

- **Do not assume tools are pre-installed.** Even on CI runners with
  pre-installed tools, assert the version. Runner images change without
  notice.

## Consequences

- Tool versions are consistent across all developers and CI environments.
- Version upgrades are pull requests with a one-line config change.
- New developers run `Install-DevBox` once and have a working environment.
- CI pipelines are self-provisioning — they do not depend on runner image
  contents.
- The platform works on bare metal, VMs, devboxes, and CI runners
  without requiring Docker.
