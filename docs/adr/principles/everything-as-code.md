# Principle: Everything as code

## Context

Organizations commonly version-control their application source code while treating configuration, infrastructure definitions,
pipeline definitions, and operational artifacts as second-class citizens — managed through UIs, wikis, shared drives,
or tribal knowledge. This creates a class of assets that cannot be reproduced, compared, audited, or rolled back.

## Principle

Every artifact required to build, test, deploy, and operate a system must be stored in version control.
This includes — but is not limited to:

- Application code and dependencies
- Infrastructure definitions
- Pipeline and deployment definitions
- Environment configuration
- Database schemas and migration scripts
- Specifications
- Test scripts and test data
- Container definitions and orchestration configuration
- Networking, firewall, and DNS configuration
- Documentation that governs operational decisions

If an artifact is required to reproduce an environment or a process, it is code. If it is code, it belongs in version control.

## Why

Three requirements drive this principle:

**Reproducibility.** Teams must be able to provision any environment in a fully automated fashion and know that any new environment
reproduced from the same configuration is identical. This is only possible when the scripts and configuration required to provision
an environment are stored in a shared, accessible system [^1].

**Traceability.** Teams must be able to pick any environment and determine quickly and precisely the versions of every dependency
used to create that environment. They must also be able to compare two versions of an environment and see what has changed
between them [^1].

**Version alignment.** A version control repository produces an infinite stream of versions — each commit is a snapshot.
When all artifacts live in the same repository, every snapshot is internally consistent by definition:
the configuration version matches the automation version matches the documentation version matches the infrastructure definitions.
There is no "which version of the config goes with which version of the code?" question — the commit answers it.
When artifacts are split across repositories, UIs, or manual stores, version alignment becomes an explicit coordination problem
that must be solved through naming conventions, tagging discipline, or cross-references — all of which are fragile.

These requirements yield concrete benefits: disaster recovery (rebuild from scratch), auditability (who changed what and when),
higher quality (faster feedback loops), capacity management (horizontal scaling from known-good definitions),
and rapid response to defects (rollback to a known-good state).

## The anti-pattern

Storing configuration or operational state outside version control — in UI-managed settings, variable libraries, shared documents,
or manual runbooks. These assets cannot be diffed, reviewed, tested, or reproduced. They drift - and sometimes fails - silently.

DORA's research explicitly identifies this as a common pitfall: applying version control only to application code,
rather than to everything required to reproduce testing and production environments [^1].

## How to apply

When evaluating where a value, definition, or process should live, ask: _can this be diffed, reviewed, and rolled back?_
If not, it must move into version control. Prefer tools and platforms that store their configuration as files in a repository
over those that store it in databases, UIs, or proprietary formats.

This principle is technology-agnostic. It applies regardless of which version control system, infrastructure tooling,
or deployment platform is in use.

## References

[^1]: DORA, [Version control](https://dora.dev/capabilities/version-control/) — Research-backed capability identifying comprehensive version control as a predictor of continuous delivery, with reproducibility and traceability as the two core requirements.
