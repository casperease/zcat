# Automation docs

## Core principle

[**Zero ceremony, hard to fail**](adr/zero-ceremony-poka-yoke.md) — every
design choice is evaluated against two questions: "Does this add ceremony?"
and "Can the author get this wrong?"

## Design principles

The "why" behind how we write code.

- [Single-responsibility functions](adr/single-responsibility-functions.md) — keep functions focused so they are easy to write, test, and debug
- [Fail fast with assertions](adr/fail-fast-with-asserts.md) — catch errors at the source, not three layers down
- [Idempotent state functions](adr/idempotent-state-functions.md) — re-runs are always safe
- [Sensible defaults](adr/sensible-defaults.md) — the zero-arg call does the right thing
- [Never depend on $PWD](adr/never-depend-on-pwd.md) — functions work from anywhere

## Implementation decisions

The "how" that makes the principles concrete.

- [One function per file](adr/one-function-per-file.md) — makes discovery automatic and eliminates export ceremony
- [Use .ps1 not .psm1](adr/use-ps1-not-psm1.md) — shared scope without boilerplate loaders
- [Approved verbs](adr/respect-pwsh-verb-rules.md) — enforced naming so functions are self-documenting
- [Uniform formatting](adr/uniform-formatting.md) — tools enforce style so humans do not have to
- [Log before invoke](adr/log-before-invoke.md) — automatic, not opt-in
- [Vendor dependencies](adr/vendor-toolset-dependencies.md) — determinism without a restore step
- [Prefer Az CLI](adr/prefer-az-cli.md) — avoids assembly hell, no module ceremony

## Other docs

- [FAQ](faq.md) — common questions about the module system
