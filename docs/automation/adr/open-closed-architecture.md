# ADR: Open/closed architecture

## Context

The Open/Closed Principle (the O in SOLID) states that a system should be open for extension but closed for modification.
In this platform, that translates to a concrete rule:
**you grow the system by adding files and folders, never by editing the infrastructure that discovers them.**

PowerShell module systems typically require hand-maintained manifests, explicit import lists, or registration steps.
Each new function means editing a `.psd1`, updating an export list, or adding a line to a loader script.
These edit-to-extend workflows create merge conflicts, stale manifests, and "I added the function but forgot to export it" bugs.

This platform eliminates that entire class of problems.
The resolver generates manifests dynamically by scanning the filesystem. The importer discovers modules by convention.
Adding capability never requires touching existing code.

### Why this matters for PowerShell specifically

**No linker catches missing exports.** In compiled languages, a missing export causes a build error.
In PowerShell, a function that exists in a file but is missing from `FunctionsToExport` silently does not load.
The caller gets a confusing "command not found" at runtime — often in CI, often after the PR already merged.
Dynamic manifest generation eliminates this failure mode entirely.

**Hand-maintained lists rot.** A `.psd1` manifest with an explicit `FunctionsToExport` list is a second source of truth
that must stay in sync with the actual files.
Every rename, move, or delete requires updating both the file and the manifest.
People forget. Reviews miss it. The list drifts.
Filesystem-driven discovery means the filesystem _is_ the manifest — there is no second source of truth to keep in sync.

**Merge conflicts on shared files.** When every new function requires editing a central manifest or loader,
two developers adding functions in parallel will conflict on that file. The conflict is trivial but annoying, and it blocks CI.
Convention-based discovery means parallel additions never touch the same file.

**Onboarding cost compounds.** "To add a function, create a file, then edit the manifest, then update the export list,
then add it to the loader" is four steps where one would do.
Each extra step is a place a newcomer can get stuck. "Drop a `.ps1` file in the folder" is self-evident.

### How the platform implements open/closed

| Extension point            | How you extend it                        | What you never modify                   |
| -------------------------- | ---------------------------------------- | --------------------------------------- |
| Add a function to a module | Create `Verb-Noun.ps1` in the module dir | No manifest, no export list, no loader  |
| Add a private helper       | Create `Verb-Noun.ps1` in `private/`     | No manifest, no export list, no loader  |
| Add a new module           | Create a folder under `automation/`      | Not `importer.ps1`, not `Resolver.psm1` |
| Add a vendor dependency    | Drop the module in `.vendor/`            | Not `importer.ps1`, not `Resolver.psm1` |

Every row follows the same pattern: the extension is a new file or folder, and the infrastructure discovers it automatically.

### Patterns that violate open/closed

| Pattern                                                         | Problem                                                    | Fix                                                                        |
| --------------------------------------------------------------- | ---------------------------------------------------------- | -------------------------------------------------------------------------- |
| Adding an `if` branch in `importer.ps1` for a special module    | Infrastructure now has module-specific knowledge           | Make the module conform to the convention, or add a general-purpose hook   |
| Hand-maintaining a `.psd1` with an explicit `FunctionsToExport` | Second source of truth that drifts from the filesystem     | Let `New-DynamicManifest` generate it                                      |
| A loader script that lists modules in a specific order          | Adding a module requires editing the loader                | If ordering matters, encode it in naming convention or dependency metadata |
| A central "registry" hashtable mapping names to functions       | Every new function requires editing the registry           | Use `Get-Command -Module` or convention-based lookup                       |
| Checking module names in conditionals (`if ($mod -eq 'Foo')`)   | Infrastructure is coupled to a specific module's existence | Use a capability check or convention instead of a name check               |

### Convention over configuration

The open/closed guarantee rests on conventions:

- **File name = function name.** `Get-Foo.ps1` exports `Get-Foo`. No mapping table needed.
- **Folder = module.** A directory under `automation/` with `.ps1` files is a module. No registration needed.
- **Root = public, `private/` = private.** Export visibility is determined by file location. No attribute or annotation needed.

These conventions are rigid by design. Rigidity is what makes the system predictable and extensible.
If every module followed its own structure, the resolver could not generate manifests automatically,
and you would be back to hand-maintained configuration.

## Decision

The platform must remain open for extension and closed for modification. Concretely:

### Rules

- **Extend by adding, not editing.** New functions, modules, and dependencies are added as files and folders.
  Existing infrastructure files (`importer.ps1`, `Resolver.psm1`) are not modified to accommodate new content.

- **No hand-maintained manifests.** Module manifests are generated dynamically by `New-DynamicManifest`.
  Do not create or edit `.psd1` files manually.
  The filesystem is the single source of truth for what a module contains and exports.

- **Infrastructure is content-agnostic.** The importer and resolver must not contain references to specific module names, function names,
  or business logic. They operate on conventions (folder structure, file naming) and treat all conforming content identically.

- **Conventions are mandatory.** The conventions that enable automatic discovery (file name = function name, folder = module,
  root = public) are not suggestions. Code that does not follow them will not be discovered,
  and the fix is to make the code conform — not to add special-case handling in the infrastructure.

- **Special cases go in the module, not the loader.** If a module needs custom initialization,
  it handles that internally (e.g., a private helper called from its public functions).
  The loader does not gain module-specific branches.

## Consequences

- Adding a function is a one-step operation: create the file.
- Parallel development never conflicts on infrastructure files.
- The resolver and importer are stable — they change only when the conventions themselves change, which is rare.
- Onboarding is trivial: "put a file here, it works."
- Debugging module loading issues reduces to "is the file in the right place with the right name?" —
  never "is it registered in three different places?"
- The tradeoff is rigidity: modules that do not follow convention are invisible to the system.
  This is intentional — the cost of one naming fix is far lower than the cost of maintaining special-case infrastructure.
