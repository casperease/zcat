# Zcat.Meta

Static configuration database for the multi-customer platform. All the "configurable but rarely changing" entities live here in `config/meta.yml` — customers, environments, environment types, subscriptions.

## The data model

**Customers** — each customer has a shortname (the key), details, and a list of environment types they use. The shortname flows into resource names, subscriptions, and deployment targets.

**Environments** — deployment stages: `dev`, `test`, `preprod`, `prod`. Each maps to a subscription type (`prod` or `nonprod`). These are universal — every customer gets all of them.

**Environment types** — what gets deployed. Split into `customer` types (per-customer: `core_customer`, `workspace_bi`, etc.) and `shared` types (one instance for all: `orthog`). Each type declares its subtypes (`sub`, `env`).

**The matrix** — a customer's actual deployments are the cross product of their environment types and the environments. Customer `blue` with types `[core_customer, workspace_bi]` gets 8 deployments: 4 environments times 2 types.

## Usage

Public functions follow the `Get-Meta*` pattern — look up customers, environments, environment types (filterable by scope), or the full validated configuration. Results are cached after first load.

## Validation

The configuration is validated on first load via `Assert-MetaConfiguration`. It checks referential integrity (customer types exist in the catalog, subscription types are valid), no duplicates, no overlap between customer and shared types, required fields, and valid identifiers. `Assert-YmlNaming` enforces snake_case on all property keys.

## Editing the config

Edit `config/meta.yml` directly. Re-run the importer to pick up changes (clears the cache). Validation runs automatically — invalid configs fail fast with specific error messages.
