# ADR: Uniform formatting

## Context

When code formatting is inconsistent, every pull request contains two
kinds of changes: the actual logic change and incidental formatting
differences. Reviewers have to mentally separate the two, and they will
miss real changes hidden in reformatting noise. This is not a theoretical
concern — it is the single biggest waste of review time in any codebase
without enforced formatting.

Inconsistent formatting also poisons `git blame`. A line that was
reformatted shows the reformatter as the last author, not the person who
wrote the logic. `git diff` becomes noisy, `git log -p` becomes
unreadable, and bisecting across formatting changes becomes painful.

The fix is simple: pick one style, enforce it mechanically, and never
discuss it again. The specific choices matter far less than the fact that
everyone uses the same ones.

### Our formatting choices

**Indentation: 4 spaces.** This is the PowerShell community default, used
by Microsoft's own modules and endorsed by PSScriptAnalyzer. Tabs are not
used.

**Brace style: K&R (opening brace on same line).** This is the most common
style in PowerShell. The `PSPlaceOpenBrace` rule enforces it.

```powershell
# YES — K&R style
if ($condition) {
    Do-Something
}

# NO — Allman style
if ($condition)
{
    Do-Something
}
```

**Variable casing: PascalCase for parameters and scoped variables,
camelCase for locals.** This makes it immediately clear in a diff whether
a variable is a parameter, module-level state, or a throwaway local.

```powershell
function Get-Config {
    param(
        [string] $EnvironmentName        # PascalCase — parameter
    )

    $script:ConfigCache = ...             # PascalCase — module state
    $configPath = Join-Path ...           # camelCase  — local
}
```

**Encoding: UTF-8 without BOM.** BOM causes issues with many tools (git
diff, Unix utilities, some editors). PSScriptAnalyzer's
`PSUseBOMForUnicodeEncodedFile` rule is excluded because we explicitly
do not want BOM.

**Line endings: LF.** Consistent across Windows, macOS, and Linux. Git
handles conversion via `.gitattributes` and `.editorconfig`.

**Trailing whitespace: trimmed.** Invisible characters that show up as
diff noise. Editors trim on save via `.editorconfig`.

**Max line length: 120 characters.** Wide enough for PowerShell's verbose
syntax, narrow enough to avoid horizontal scrolling in side-by-side diffs.

## Decision

All code follows a single, mechanically enforced formatting style. No
exceptions, no per-file overrides, no "I prefer it this way."

### How this is enforced

- **`.editorconfig`** — configures editors to use the correct indent
  style, charset, line endings, and trailing whitespace behavior. Supported
  by VS Code, JetBrains, vim, and most modern editors without plugins.

- **PSScriptAnalyzer formatting rules** (enabled in
  `PSScriptAnalyzerSettings.psd1`):
  - `PSPlaceOpenBrace` — K&R brace style
  - `PSAvoidTrailingWhitespace` — no trailing spaces (enabled by default)

- **Custom PSScriptAnalyzer rule `Measure-VariableCasing`**
  (`automation/.scriptanalyzer/VariableCasing.psm1`) — enforces PascalCase
  for parameters and scoped variables, camelCase for locals. Scriptblock
  params and automatic variables are excluded.

- **L2 test suite** — `Test-ScriptAnalyzer.Tests.ps1` runs all
  PSScriptAnalyzer rules (including custom rules) against every `.ps1` and
  `.psm1` file in the codebase. Formatting violations fail the build.

### Rules

- **Let the tools do the work.** Configure your editor to read
  `.editorconfig`. PSScriptAnalyzer catches violations in the test suite.
  Do not hand-format — you will get it wrong and create a diff.

- **Do not debate formatting.** Uniformity is the goal — taste is
  something you get used to. If you genuinely believe a formatting choice
  should change, update the tools, the tests, and *every file in the
  codebase* in one sweep. Partial adoption of a new style is worse than
  either style on its own.

## Consequences

- Pull request diffs contain only logic changes. Reviewers see what
  actually changed.
- `git blame` points at the author of the logic, not the last reformatter.
- `git diff` is clean and readable — no noise from whitespace, brace
  placement, or casing differences.
- New contributors produce correctly formatted code from the first commit
  because their editor reads `.editorconfig` and PSScriptAnalyzer catches
  the rest.
- Formatting discussions never happen. The tools decide, not the team.
