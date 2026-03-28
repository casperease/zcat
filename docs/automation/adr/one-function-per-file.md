# ADR: One function per file

## Context

We need a convention for how functions map to files within a module. The two
common approaches are:

1. **Multiple functions per file** — group related functions together, use AST
   parsing or manual export lists to determine what gets exported.
2. **One function per file** — each `.ps1` file contains exactly one function,
   the file name matches the function name (`Get-Foo.ps1` → `function Get-Foo`).

### Why one function per file

**File listing = module API.** Running `ls` on a module folder immediately shows
every public function. No need to open files, read manifests, or run
`Get-Command -Module`. New contributors can understand a module's surface area
in seconds.

**No AST parsing needed for exports.** When file name equals function name, the
manifest generator can derive `FunctionsToExport` directly from file names —
a string operation, not a parse. AST parsing is slow (~25ms per file) and adds
complexity. With one-function-per-file, the resolver just uses `$file.BaseName`
and skips the parser entirely. This directly impacts import speed.

**Merge conflicts disappear.** When two people add functions to the same file,
they conflict. When each function is its own file, parallel work on different
functions never touches the same file. Git blame is also trivially useful — each
file has a single author history.

**Searchability.** Looking for `Get-Customer`? The file is `Get-Customer.ps1`.
No grepping, no guessing which file it lives in. Every editor's file-open
dialog becomes a function search.

**Consistent granularity.** There is no judgment call about "which functions
belong together" or when a file has grown too large and needs splitting. The
rule is mechanical: one function, one file, names match.

**Test file pairing.** Each function file pairs naturally with a test file:
`Get-Foo.ps1` → `tests/Get-Foo.Tests.ps1`. No ambiguity about which test file
covers which function.

## Decision

Each `.ps1` file contains exactly one exported function. The file name matches
the function name: `Get-Foo.ps1` must contain `function Get-Foo`.

### How this is enforced

- **`Test-Automation.Tests.ps1`** — validates every `.ps1` file:
  file name must be `Verb-Noun` format, must contain exactly one function,
  and function name must match the file basename.
- **Test file naming** — the same test validates that every `.Tests.ps1`
  file also follows `Verb-Noun.Tests.ps1` format.
- **Resolver** — `New-DynamicManifest` derives `FunctionsToExport`
  directly from `$file.BaseName`, so files that do not follow the
  convention will not export correctly.

## Consequences

- File name is the function name — `$file.BaseName` is the export list
- AST parsing is eliminated from the module resolver's hot path
- Module contents are visible from a directory listing alone
- Each function has its own git history and blame
- Test files map 1:1 to function files
- Modules with many small functions will have many small files — this is
  acceptable and preferred over fewer large files
