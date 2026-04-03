# Documentation

## Core principle

[**Zero ceremony, hard to fail**](adr/automation/zero-ceremony-poka-yoke.md) — every design choice is evaluated against two questions:
"Does this add ceremony?" and "Can the author get this wrong?"

## Automation ADRs

The "why" and "how" behind the PowerShell automation layer.

### Design principles

- [Single-responsibility functions](adr/automation/single-responsibility-functions.md) — keep functions focused so they are easy to write, test, and debug
- [Open/closed architecture](adr/automation/open-closed-architecture.md) — extend by adding files, never by editing infrastructure
- [Fail fast with assertions](adr/automation/fail-fast-with-asserts.md) — catch errors at the source, not three layers down
- [Idempotent state functions](adr/automation/idempotent-state-functions.md) — re-runs are always safe
- [Sensible defaults](adr/automation/sensible-defaults.md) — the zero-arg call does the right thing
- [Console output matters](adr/automation/console-output-matters.md) — every line of output is a UX decision
- [Error handling](adr/automation/error-handling.md) — fail immediately, no warnings, no middle ground
- [Never depend on $PWD](adr/automation/never-depend-on-pwd.md) — functions work from anywhere

### Implementation decisions

- [One function per file](adr/automation/one-function-per-file.md) — makes discovery automatic and eliminates export ceremony
- [Use .ps1 not .psm1](adr/automation/use-ps1-not-psm1.md) — shared scope without boilerplate loaders
- [Approved verbs](adr/automation/respect-pwsh-verb-rules.md) — enforced naming so functions are self-documenting
- [Uniform formatting](adr/automation/uniform-formatting.md) — tools enforce style so humans do not have to
- [Log before invoke](adr/automation/log-before-invoke.md) — automatic, not opt-in
- [Vendor dependencies](adr/automation/vendor-toolset-dependencies.md) — determinism without a restore step
- [Controlling system-wide deps](adr/automation/controlling-systemwide-deps.md) — version-locked, platform-aware, no container required
- [Effective in enterprises](adr/automation/effective-in-enterprises.md) — no network paths, no gallery, no profile dependency
- [Prefer Az CLI](adr/automation/prefer-az-cli.md) — avoids assembly hell, no module ceremony
- [Conventional folder structure](adr/automation/conventional-folder-structure.md) — predictable layout for modules, tests, assets, and output
- [Dedicated output directory](adr/automation/dedicated-output-directory.md) — all generated artifacts go to `out/`
- [Environment variables](adr/automation/environment-variables.md) — when and how to use them
- [Cross-platform](adr/automation/cross-platform.md) — runs on Windows, Linux, and macOS
- [Avoid deep nesting](adr/automation/avoid-deep-nesting.md) — flat code is readable code
- [Never use semicolons](adr/automation/never-use-semicolons.md) — one statement per line
- [Prefer foreach over ForEach-Object](adr/automation/prefer-foreach-over-foreach-object.md) — clarity and debuggability
- [Automatic variable pitfalls](adr/automation/automatic-variable-pitfalls.md) — `$?`, `$_`, `$LASTEXITCODE` and their traps
- [Use proper package managers](adr/automation/use-proper-package-managers.md) — system tools via native package managers

### SOLID principles that don't apply

- **Liskov Substitution (L)** — LSP governs subtype hierarchies. This platform has no class hierarchies or subtype relationships.
- **Interface Segregation (I)** — ISP targets fat interfaces. PowerShell functions don't implement interfaces. The public/private split handles surface area.
- **Dependency Inversion (D)** — DIP requires a formal abstraction boundary. `Assert-Command` and `Invoke-CliCommand` provide light indirection, but not a formal abstraction layer.

### DRY and KISS

- **KISS** — This is [zero ceremony, hard to fail](adr/automation/zero-ceremony-poka-yoke.md). The foundational ADR's first test — "Does this add ceremony?" — is the KISS test.
- **DRY** — Enforced structurally: [open/closed architecture](adr/automation/open-closed-architecture.md) eliminates manifest duplication, [sensible defaults](adr/automation/sensible-defaults.md) pull versions from config, [one function per file](adr/automation/one-function-per-file.md) makes the file name the export name.

## Pipeline ADRs

How Azure DevOps pipelines interact with the automation layer.

- [Pipeline runner pattern](adr/pipelines/pipeline-runner-pattern.md) — all pipeline steps invoke PowerShell through a single runner
- [Custom template discipline](adr/pipelines/custom-template-discipline.md) — when and how to use ADO templates
- [Pipeline variables](adr/pipelines/pipeline-variables.md) — setting ADO output variables from PowerShell
- [Pipeline detection](adr/pipelines/pipeline-detection.md) — how functions adapt to pipeline vs. local context
- [Dual authentication](adr/pipelines/dual-authentication.md) — pipeline system token vs. local Az token

## Notes

- [Disable VS Code Copilot](notes/disable-vscode-copilot.md)
- [SQL project SDK migration plan](notes/sqlproj-sdk-migration-plan.md)

## Other

- [FAQ](faq.md) — common questions about the module system
