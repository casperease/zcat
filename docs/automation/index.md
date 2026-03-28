# Automation docs

## Core principle

[**Zero ceremony, hard to fail**](adr/zero-ceremony-poka-yoke.md) — every design choice is evaluated against two questions:
"Does this add ceremony?" and "Can the author get this wrong?"

## Design principles

The "why" behind how we write code.

- [Single-responsibility functions](adr/single-responsibility-functions.md) — keep functions focused so they are easy to write, test, and debug
- [Open/closed architecture](adr/open-closed-architecture.md) — extend by adding files, never by editing infrastructure
- [Fail fast with assertions](adr/fail-fast-with-asserts.md) — catch errors at the source, not three layers down
- [Idempotent state functions](adr/idempotent-state-functions.md) — re-runs are always safe
- [Sensible defaults](adr/sensible-defaults.md) — the zero-arg call does the right thing
- [Console output matters](adr/console-output-matters.md) — every line of output is a UX decision
- [Error handling](adr/error-handling.md) — fail immediately, no warnings, no middle ground
- [Never depend on $PWD](adr/never-depend-on-pwd.md) — functions work from anywhere

### SOLID principles that don't apply

- **Liskov Substitution (L)** — LSP governs subtype hierarchies. This platform has no class hierarchies or subtype relationships.

- **Interface Segregation (I)** — ISP targets fat interfaces that force clients to depend on methods they don't use.
  PowerShell functions don't implement interfaces. The public/private split and module boundaries handle surface area minimisation.

- **Dependency Inversion (D)** — DIP requires an abstraction boundary that both high-level and low-level code program against.
  The `Assert-Command` pattern and `Invoke-CliCommand` wrapper provide light indirection, but not a formal abstraction layer.

### DRY and KISS

- **KISS (Keep It Simple)** — This is [zero ceremony, hard to fail](adr/zero-ceremony-poka-yoke.md).
  The foundational ADR's first test — "Does this add ceremony?" — is the KISS test.
  Every design choice in the platform is already evaluated against simplicity.

- **DRY (Don't Repeat Yourself)** — Enforced structurally across several decisions.
  [Open/closed architecture](adr/open-closed-architecture.md) eliminates the duplicated source of truth between manifests and files.
  [Sensible defaults](adr/sensible-defaults.md) pull versions from config so values aren't repeated at call sites.
  [One function per file](adr/one-function-per-file.md) makes the file name the function name and the export name — no parallel lists to keep in sync.
  The resolver itself exists so modules don't each repeat their own loading logic.

## Implementation decisions

The "how" that makes the principles concrete.

- [One function per file](adr/one-function-per-file.md) — makes discovery automatic and eliminates export ceremony
- [Use .ps1 not .psm1](adr/use-ps1-not-psm1.md) — shared scope without boilerplate loaders
- [Approved verbs](adr/respect-pwsh-verb-rules.md) — enforced naming so functions are self-documenting
- [Uniform formatting](adr/uniform-formatting.md) — tools enforce style so humans do not have to
- [Log before invoke](adr/log-before-invoke.md) — automatic, not opt-in
- [Vendor dependencies](adr/vendor-toolset-dependencies.md) — determinism without a restore step
- [Controlling system-wide deps](adr/controlling-systemwide-deps.md) — version-locked, platform-aware, no container required
- [Effective in enterprises](adr/effective-in-enterprises.md) — no network paths, no gallery, no profile dependency
- [Prefer Az CLI](adr/prefer-az-cli.md) — avoids assembly hell, no module ceremony

## Other docs

- [FAQ](faq.md) — common questions about the module system
