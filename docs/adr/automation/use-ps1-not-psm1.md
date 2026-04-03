# ADR: Use `.ps1` for function files, not `.psm1`

## Context

We use a one-function-per-file layout with public/private separation by folder.
Public functions need to call private functions without the author adding any imports or boilerplate.
This requires all function files within a module to share the same scope.

We initially used `.psm1` for all function files because PowerShell originally positioned `.psm1` as the submodule format: folder = module, `.psm1` = submodule.

### What we learned

**The `.psm1` extension exists to create a scope boundary.** That is its entire purpose versus a plain `.ps1` file.
Each `.psm1` loaded via `NestedModules` in a manifest gets its own isolated module scope — by design, not by accident.

Microsoft designed `NestedModules` with `.psm1` files for **dependency composition** — independent sub-libraries (like referencing a NuGet package),
each with their own encapsulated scope and controlled exports. This works well for that purpose.

Our use case is different: we want **code organization** — splitting one module's internals across files. For this, scope isolation is harmful:

- A private helper in one `.psm1` is invisible to a public function in another `.psm1` unless explicitly exported (which defeats "private")
- Module-scoped variables (`$script:`) are isolated per `.psm1`
- Sharing state between nested `.psm1` files requires `$global:` (a code smell)

### Community history

The PowerShell community hit these same problems between 2012-2016 and converged on a standard pattern:

- Individual functions live in `.ps1` files (no scope boundary)
- A single root `.psm1` dot-sources all `.ps1` files into one shared scope
- Public/Private folder convention controls exports
- `.ps1` files in a manifest's `NestedModules` run in the module's session state (shared scope), unlike `.psm1` files which get isolated scope

This pattern is used by dbatools, PSFramework, and Microsoft's own modules. Build tools like Plaster, Stucco, and ModuleBuilder codified it.
Microsoft's docs eventually endorsed it.

### What we tried

1. **`.psm1` in `NestedModules`** — each file gets isolated scope. Public functions cannot see private functions. Does not meet our requirements.

2. **Generated `_loader.psm1` with `ScriptBlock::Create`** — reads `.psm1` file content as text and evaluates it in a shared scope. Works, but non-standard and adds complexity for no benefit over just using `.ps1`.

3. **`.ps1` in `NestedModules`** — runs in the module's session state (shared scope). Public and private functions can see each other. Manifest-only solution, no loader needed. This is the standard community pattern.

## Decision

Use `.ps1` for all function files. Reserve `.psm1` for actual module files (`Resolver.psm1`).

### How this is enforced

- **Resolver** — `New-DynamicManifest` only scans for `*.ps1` files. Any `.psm1` file inside a module folder is silently ignored.
- **`Test-Automation.Tests.ps1`** — only discovers `.ps1` files for validation, reinforcing that `.psm1` is not used for function files.

## Consequences

- Function files use `.ps1` extension: `Get-Foo.ps1`, not `Get-Foo.psm1`
- `New-DynamicManifest` lists `.ps1` files in `NestedModules` — they share the module's session state natively
- No `_loader.psm1` workaround needed — manifest-only solution
- Private functions are automatically available to public functions
- Aligns with the established PowerShell community convention
- `Resolver.psm1` remains `.psm1` because it is a standalone module, not a function file within a module
