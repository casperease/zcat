# ADR: Respect PowerShell approved verbs

## Context

PowerShell has a curated list of approved verbs (`Get-Verb`),
organized into groups (Common, Communications, Data, Diagnostic, Lifecycle, Security) with precise definitions for each.
This is not a suggestion — it is a deliberate design decision by the PowerShell team, and it is one of the language's true strengths.

### Why this matters

**Verbs are a shared vocabulary.** When a user sees `Get-`, they know it reads without modifying.
When they see `Set-`, they know it writes.
When they see `Test-`, they know it returns a boolean. When they see `Assert-`, they know it throws on failure.
This contract is universal across every PowerShell module, every vendor, every team.
A user who has never seen your code can predict what `Get-MetaConfiguration` does from the verb alone.

**Verbs encode behavior guarantees.** The approved verbs are not just naming conventions — they carry semantic promises:

| Verb                                       | Guarantee                                          | Will not                   |
| ------------------------------------------ | -------------------------------------------------- | -------------------------- |
| `Get-`                                     | Safe to call, read-only                            | Change state               |
| `Test-`                                    | Returns `[bool]`                                   | Throw on the negative case |
| `Assert-`                                  | Throws on failure                                  | Return false               |
| `New-`                                     | Creates a resource                                 | Update existing resources  |
| `Set-`                                     | Replaces data on existing, or creates if missing   |                            |
| `Remove-`                                  | Deletes a resource                                 | Archive or soft-delete     |
| `Install-`                                 | Places a resource and initializes it               |                            |
| `Invoke-`                                  | Runs a command or method, transparent pass-through |                            |
| `Update-`                                  | Brings an existing resource up-to-date             | Create new resources       |
| `Build-`                                   | Creates an artifact from input files               |                            |
| `Convert-` / `ConvertTo-` / `ConvertFrom-` | Transforms data between representations            |                            |

**`New-` not `Create-`.** `Create` is not an approved verb. Use `New-` for all resource creation. This is the single most common mistake.

When every function in the codebase respects these guarantees,
a user can reason about behavior from the function name without reading the implementation. This is an extraordinary advantage that most languages do not offer.

**Discovery works.** `Get-Command -Verb Install` shows every install function. `Get-Command -Noun Poetry` shows every poetry function.
This only works when verbs are consistent. A function named `Setup-Poetry` would not appear in either search.

**Tab completion works.** Users type `Get-` and tab through all getters. They type `Install-` and see all installable tools.
Non-standard verbs break this workflow and hide functions from discovery.

### The approved verb groups

#### Common

| Verb     | Meaning                                                          |
| -------- | ---------------------------------------------------------------- |
| `Add`    | Adds a resource to a container                                   |
| `Clear`  | Removes contents from a container without deleting the container |
| `Close`  | Makes a resource inaccessible or unusable                        |
| `Copy`   | Copies a resource to another name or container                   |
| `Get`    | Retrieves a resource (read-only, no side effects)                |
| `Move`   | Moves a resource from one location to another                    |
| `New`    | Creates a resource                                               |
| `Open`   | Makes a resource accessible or usable                            |
| `Remove` | Deletes a resource from a container                              |
| `Rename` | Changes the name of a resource                                   |
| `Reset`  | Sets a resource back to its original state                       |
| `Search` | Creates a reference to a resource in a container                 |
| `Select` | Locates a resource in a container                                |
| `Set`    | Replaces data on an existing resource                            |
| `Show`   | Makes a resource visible to the user                             |

#### Data

| Verb          | Meaning                                                 |
| ------------- | ------------------------------------------------------- |
| `Compare`     | Evaluates data from one resource against another        |
| `Convert`     | Changes data bidirectionally between representations    |
| `ConvertFrom` | Converts from a specific format to general objects      |
| `ConvertTo`   | Converts from general objects to a specific format      |
| `Export`      | Encapsulates input into a persistent store (file, etc.) |
| `Import`      | Creates a resource from data in a persistent store      |
| `Merge`       | Creates a single resource from multiple resources       |
| `Publish`     | Makes a resource available to others                    |
| `Save`        | Preserves data to avoid loss                            |
| `Update`      | Brings a resource up-to-date                            |

#### Lifecycle

| Verb        | Meaning                                             |
| ----------- | --------------------------------------------------- |
| `Assert`    | Affirms the state of a resource (throws on failure) |
| `Build`     | Creates an artifact from input files                |
| `Deploy`    | Sends a solution to a remote target for consumption |
| `Disable`   | Configures a resource to an inactive state          |
| `Enable`    | Configures a resource to an active state            |
| `Install`   | Places a resource in a location and initializes it  |
| `Invoke`    | Performs an action such as running a command        |
| `Start`     | Initiates an operation                              |
| `Stop`      | Discontinues an activity                            |
| `Uninstall` | Removes a resource from a location                  |

#### Diagnostic

| Verb      | Meaning                                                            |
| --------- | ------------------------------------------------------------------ |
| `Debug`   | Examines a resource to diagnose problems                           |
| `Measure` | Identifies resources consumed by an operation                      |
| `Test`    | Verifies the operation or consistency of a resource (returns bool) |
| `Trace`   | Tracks activities of a resource                                    |

#### Communications

| Verb      | Meaning                               |
| --------- | ------------------------------------- |
| `Read`    | Acquires information from a source    |
| `Write`   | Adds information to a target          |
| `Send`    | Delivers information to a destination |
| `Receive` | Accepts information from a source     |

#### Security

| Verb        | Meaning                                   |
| ----------- | ----------------------------------------- |
| `Block`     | Restricts access to a resource            |
| `Grant`     | Allows access to a resource               |
| `Protect`   | Safeguards a resource from attack or loss |
| `Revoke`    | Removes access to a resource              |
| `Unblock`   | Removes restrictions to a resource        |
| `Unprotect` | Removes safeguards from a resource        |

### Common mistakes

| Wrong                  | Right                              | Why                                                                     |
| ---------------------- | ---------------------------------- | ----------------------------------------------------------------------- |
| `Setup-DevBox`         | `Install-DevBox`                   | `Setup` is not an approved verb; `Install` means "place and initialize" |
| `Create-ResourceGroup` | `New-ResourceGroup`                | `Create` is not approved; `New` means "creates a resource"              |
| `Delete-Config`        | `Remove-Config`                    | `Delete` is not approved; `Remove` means "deletes from a container"     |
| `Run-Pipeline`         | `Invoke-Pipeline`                  | `Run` is not approved; `Invoke` means "performs an action"              |
| `Check-Version`        | `Test-Version` or `Assert-Version` | `Check` is not approved; `Test` returns bool, `Assert` throws           |
| `Load-Module`          | `Import-Module`                    | `Load` is not approved; `Import` means "creates from persistent store"  |
| `Parse-Yaml`           | `ConvertFrom-Yaml`                 | `Parse` is not approved; `ConvertFrom` means "converts from format X"   |
| `Validate-Config`      | `Assert-Config` or `Test-Config`   | `Validate` is not approved; use `Assert` (throws) or `Test` (bool)      |
| `Fetch-Data`           | `Get-Data`                         | `Fetch` is not approved; `Get` means "retrieves a resource"             |
| `Execute-Command`      | `Invoke-Command`                   | `Execute` is not approved; `Invoke` means "performs an action"          |

## Decision

All functions must use approved PowerShell verbs. No exceptions.

### Rules

- **Use only verbs from `Get-Verb`.** If the verb you want is not in the list, find the approved verb that matches the semantics. The table above and the common mistakes section cover the most frequent cases.

- **Respect the semantic contract.** A `Get-` function must not modify state. A `Test-` function must return `[bool]`. An `Assert-` function must throw on failure. The verb is a promise to the caller.

- **Use `Test-` for boolean queries, `Assert-` for preconditions.** Both verify state, but `Test-` returns true/false for the caller to decide what to do,
  while `Assert-` throws immediately if the condition is not met.
  A function should never be named `Test-` and throw, or named `Assert-` and return false.

- **Use `Invoke-` for transparent command wrappers.** `Invoke-Python`, `Invoke-Poetry`, `Invoke-Dotnet` — these run the underlying tool.
  They do not decide what to run or handle the output semantically. The caller controls the command; the function provides the invocation plumbing.

- **Use `ConvertTo-`/`ConvertFrom-` for format transformations.** Not `Parse-`, `Serialize-`, `Transform-`, or `Format-` (which means "arranges for display," not "converts").

### How this is enforced

- **PSScriptAnalyzer rule `PSUseApprovedVerbs`** (built-in, enabled) — warns on any function that uses a verb not in the `Get-Verb` list. Runs as part of the L2 test suite via `Test-ScriptAnalyzer.Tests.ps1`.

## Consequences

- Every function is discoverable via `Get-Command -Verb` and `Get-Command -Noun`.
- Users can predict function behavior from the name without reading code.
- Code reads as natural language: `Assert-Command python`, `Install-Poetry`, `Get-MetaConfiguration`, `Test-IsAdministrator`.
- PSScriptAnalyzer warns on unapproved verbs, catching mistakes before code review.
- New team members familiar with any PowerShell module can immediately navigate the codebase because the vocabulary is shared.
