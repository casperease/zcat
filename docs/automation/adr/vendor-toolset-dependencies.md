# ADR: Vendor toolset dependencies

## Context

PowerShell modules from the gallery change without notice. A `2.x` version
that worked yesterday can behave differently today because the gallery
resolved a different patch version on a different machine. This causes
three problems:

1. **Non-determinism.** Two developers running `Install-Module` on the same
   day can get different versions. CI machines that rebuild images get
   whatever version is current at image-build time. Bugs that only
   reproduce on one machine are almost always version skew.

2. **Slow startup.** `Install-Module` checks the gallery on every call.
   Even when the module is already installed, the network round-trip adds
   seconds. In an interactive shell that loads on every new tab, this adds
   up fast. Gallery outages turn slow into broken.

3. **Implicit dependency chain.** Modules from the gallery can pull in
   transitive dependencies. You install one module and get five. Any of
   those five can change independently, and any can conflict with another
   module in your session.

### Vendoring solves all three

Vendoring means checking the module's files directly into the repository
under `automation/.vendor/<ModuleName>/<Version>/`. The module loads from
disk with no network call, no version resolution, and no surprises.

- **Deterministic.** Every developer and every CI run uses exactly the same
  files. The version is locked by the commit, not by a gallery query.

- **Fast.** Loading from disk is sub-second. No network, no
  `Install-Module`, no `Find-Module`. Modules that are expensive to import
  (Pester, PSScriptAnalyzer) can be deferred with the `Lazy` parameter and
  only loaded on first use.

- **Explicit.** The `.vendor` folder is visible in the repository. You can
  see exactly which modules are vendored, at which versions. Upgrading is a
  conscious decision: delete the old folder, add the new one, commit.

### Exception: Az PowerShell modules

The Azure PowerShell modules (`Az.*`) are not vendored. They are too large
(hundreds of megabytes), update frequently with Azure API changes, and
carry .NET assembly dependencies that conflict when multiple versions
coexist in-process. Vendoring them would bloat the repository and create
assembly-loading issues.

See [ADR: prefer-az-cli](prefer-az-cli.md) for how we handle Azure
operations without depending on Az modules.

## Decision

All PowerShell module dependencies used by the toolset are vendored in
`automation/.vendor/`. Az PowerShell modules are excluded.

### Rules

- **Vendor into `automation/.vendor/<ModuleName>/<Version>/`.** The version
  folder ensures the module loads from the expected path and makes upgrades
  visible in diffs.

- **Check vendored modules into git.** They are part of the repository.
  This is intentional — it guarantees reproducibility without requiring a
  restore step.

- **Use `Install-VendorModule` to add new modules.** This function
  downloads from the gallery and places the files in the correct structure.
  After running it, commit the result.

- **Upgrade deliberately.** To upgrade a vendored module: remove the old
  version folder, run `Install-VendorModule` for the new version, run
  tests, commit. Never auto-upgrade.

- **Lazy-load expensive modules.** Modules like Pester and
  PSScriptAnalyzer are only needed for testing. Pass them via the `Lazy`
  parameter in `Import-VendorModules` so they do not slow down every
  shell startup.

### How this is enforced

- **`Install-VendorModule`** — the only supported way to add a vendor
  module. Downloads from the gallery and places files in the correct
  `automation/.vendor/<Name>/<Version>/` structure.
- **`Import-VendorModules`** — loads only from the `.vendor` directory.
  System-installed versions are removed from `$env:PSModulePath` to
  prevent auto-loading from outside the vendor folder.
- **Git** — vendored modules are checked in. Version changes are visible
  as diffs in pull requests.

## Consequences

- Repository size increases by the size of vendored modules. In practice
  this is small (Pester, PSScriptAnalyzer, powershell-yaml total ~15 MB).
- No network dependency for module loading. The toolset works offline and
  in air-gapped environments.
- Module upgrades show up as explicit diffs in pull requests, making
  version changes reviewable.
- Az modules must be managed through other mechanisms (system install,
  devbox, CI image) — see the prefer-az-cli ADR.
