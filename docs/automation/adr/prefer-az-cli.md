# ADR: Prefer Az CLI over Az PowerShell modules

## Context

Azure operations can be performed through two official toolchains:

1. **Az CLI** (`az`) — a standalone executable. Installed once, runs as a child process, returns JSON. No in-process dependencies.

2. **Az PowerShell modules** (`Az.*`) — .NET-based PowerShell modules. Loaded into the PowerShell session, return rich objects,
   carry hundreds of megabytes of assemblies.

Both are maintained by Microsoft and cover largely the same API surface. The question is which to use as the default.

### Problems with Az PowerShell modules

**Assembly hell.** Az modules load .NET assemblies into the PowerShell process. Once loaded, an assembly cannot be unloaded or replaced without restarting the session.
If two modules depend on different versions of the same assembly, the second module fails silently or throws cryptic `FileLoadException` errors.
This is the single most common source of "works on my machine" issues in Azure automation.

**Slow to import.** `Import-Module Az` takes 10-30 seconds depending on which sub-modules are loaded.
Even importing a single sub-module like `Az.Storage` takes several seconds due to assembly loading.
This makes interactive use painful and adds minutes to CI pipelines.

**Cannot be vendored.** The modules are too large (the full Az set is ~500 MB) and their assembly dependencies make vendoring impractical.
This means they must be installed system-wide, creating the version skew and non-determinism problems described in the vendoring ADR.

**Tight coupling to PowerShell version.** Az modules target specific .NET runtime versions. A PowerShell upgrade can break Az module loading.
An Az module upgrade can require a PowerShell upgrade. This coupling makes updates risky.

**Implicit session state.** Az modules use `Connect-AzAccount` to store credentials in session state. The connection context is global and mutable.
Functions that assume they are operating in a specific subscription context can silently operate in the wrong context if another function changed it.

### Why Az CLI is better for automation

**Process isolation.** Each `az` invocation runs in its own process. No assembly conflicts, no session state pollution, no import overhead.
The CLI starts, does its work, and exits cleanly.

**Single binary, single version.** `az` is one executable. You install it once, assert the version with `Assert-ToolVersion`, and every function uses the same tool.
No sub-module matrix, no assembly graph.

**JSON output.** `az` returns JSON by default. Parse it with `ConvertFrom-Json` and you have a PSCustomObject.
The schema is documented in the Azure REST API docs, which are the canonical reference regardless of which tool you use.

**Scriptable authentication.** `az login` stores credentials in a file that persists across processes.
Service principal auth works via environment variables (`AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`). No global session context to manage.

**Works everywhere.** `az` runs on Windows, macOS, and Linux without PowerShell-specific dependencies.
The same automation code works in PowerShell, bash, and CI pipelines interchangeably.

### When Az PowerShell modules are unavoidable

Some tasks genuinely require Az PowerShell modules — typically when the Az CLI does not expose a specific API,
or when you need deep .NET integration (e.g., working with Azure SDK types directly). These cases are rare but real.

When they arise, the Az modules must not be vendored or managed by the automation toolset. Instead:

- **Devbox**: configure the devbox definition to install the required Az modules at the correct version during provisioning.
- **CI**: install the required Az modules in the pipeline image or as an explicit pipeline step, pinned to a specific version.
- **Document the dependency**: the function's comment-based help must state which `Az.*` module it requires and at what version.

The key point: the lifecycle of Az modules is managed by the *environment*, not by the automation code.
The automation code asserts the module is present with `Assert-PsModule` and fails fast if it is not.

## Decision

Use Az CLI (`az`) for all Azure operations by default. Az PowerShell modules are a last resort when the CLI does not cover the required functionality.

### Rules

- **Default to `az` for all Azure operations.** Wrap calls in `Invoke-CliCommand` with `ConvertFrom-Json` to parse the output.

- **Assert `az` availability.** Use `Assert-Command az` and `Assert-ToolVersion -Tool 'AzCli'` at the start of functions that call `az`.

- **Do not import Az PowerShell modules in automation code.** No `Import-Module Az.*` in any function.
  If an Az module is needed, the environment must provide it, and the function must assert it with `Assert-PsModule`.

- **Do not vendor Az modules.** They are too large and their assembly dependencies make in-process versioning unsafe.
  Manage them through devbox definitions and CI pipeline configuration.

- **Pin versions in environment configuration.** When Az modules are required, the devbox or CI config must specify the exact version.
  Never rely on "whatever is installed."

- **Document Az module dependencies explicitly.** Any function that requires an Az module must state the module name and minimum version in its `.SYNOPSIS` or `.DESCRIPTION`.

## Consequences

- Azure automation code is fast to load and free of assembly conflicts.
- The same functions work in any environment that has `az` installed — no PowerShell-specific module setup required.
- The rare cases that need Az modules are handled at the environment level with explicit version pinning, not silently inside automation functions.
- Functions that call `az` return plain objects (from JSON), not Az SDK types. This is simpler to work with and has no hidden dependencies.
