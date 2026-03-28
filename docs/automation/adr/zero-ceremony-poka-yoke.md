# ADR: Zero ceremony, hard to fail

## Context

This is the foundational design principle. Every other decision in this
project derives from two goals:

1. **Zero ceremony.** Adding automation should require no boilerplate, no
   wiring, no registration, and no configuration beyond the minimum
   needed to express the intent. Drop a file, get a function.

2. **Hard to fail (poka-yoke).** The system should make mistakes
   impossible or immediately visible. If something can go wrong, the
   design should prevent it structurally — not through documentation,
   discipline, or code review.

Poka-yoke (ポカヨケ) is a manufacturing concept: design the process so
that errors cannot happen, or if they do, they are caught at the point of
origin before they propagate. Applied to automation code, this means the
platform itself enforces correctness — the author does not have to
remember to do the right thing.

### What zero ceremony looks like

**Adding a function:** create `Verb-Noun.ps1` in a module folder. No
manifest to update, no export list to maintain, no import to add. The
resolver discovers it automatically.

**Adding a module:** create a folder under `automation/`. The folder name
becomes the module name. No registration, no configuration file.

**Using a function:** dot-source `importer.ps1`. Every function from every
module is available. No `Import-Module`, no `using module`, no dependency
declarations.

**Adding a dependency:** run `Install-VendorModule`. Commit the result.
No package manager configuration, no restore step, no lock file.

**Running tests:** call `Test-Automation`. It finds all test files across
all modules automatically.

Each of these is a single action with no prerequisites and no follow-up
steps. The ceremony count is zero.

### What hard-to-fail looks like

**You cannot name a file wrong.**
[One function per file](one-function-per-file.md) — `Test-Automation.Tests.ps1`
validates that every file is `Verb-Noun.ps1`, contains exactly one function,
and the function name matches. A misnamed file fails the test suite immediately.

**You cannot use the wrong verb.**
[Approved verbs](respect-pwsh-verb-rules.md) — PSScriptAnalyzer's
`PSUseApprovedVerbs` rule rejects unapproved verbs. The author does not
need to check `Get-Verb` — the tool catches it.

**You cannot forget an assertion.**
[Fail fast with assertions](fail-fast-with-asserts.md) — the convention of
asserting every assumption inline means errors surface at the exact point
of failure with a message naming the violated assumption. Bad state cannot
silently propagate.

**You cannot break formatting.**
[Uniform formatting](uniform-formatting.md) — `.editorconfig` configures
the editor. PSScriptAnalyzer rules enforce brace style and variable casing.
The author does not need to think about formatting — the tools handle it.

**You cannot depend on $PWD.**
[Never depend on $PWD](never-depend-on-pwd.md) — a custom PSScriptAnalyzer
rule flags bare `Set-Location` calls. Functions that accidentally depend on
the working directory are caught before they run in a different context.

**You cannot publish a function that doesn't exist.**
[Use .ps1 not .psm1](use-ps1-not-psm1.md) — the resolver derives exports
from file names. There is no manifest to get out of sync — the file system
is the source of truth.

**You cannot get a stale module version.**
[Vendor dependencies](vendor-toolset-dependencies.md) — vendored modules
are checked into the repo. There is no version resolution at runtime, no
gallery call that might return a different version on a different machine.

## Decision

Every design choice in this project is evaluated against two questions:

1. **Does this add ceremony?** If the author has to do something that the
   platform could do for them, the platform should do it.

2. **Can the author get this wrong?** If a mistake is possible, the system
   should either prevent it structurally (file naming conventions, resolver
   auto-discovery) or catch it immediately (PSScriptAnalyzer rules, test
   suite assertions).

If the answer to either question is unsatisfying, the design is not done.

## Consequences

- New contributors are productive in minutes. Drop a file, write a
  function, run `Test-Automation`. There is nothing else to learn before
  the first contribution.
- The most common mistakes are impossible. The platform's structure
  prevents them, and the test suite catches the rest.
- The automation codebase stays consistent as it grows. Conventions are
  enforced mechanically, not by tribal knowledge.
- The cost of this is rigidity. The conventions are not optional. The
  tradeoff is deliberate: individual flexibility is sacrificed for
  collective reliability.
