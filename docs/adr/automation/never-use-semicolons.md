# ADR: Never use semicolons

## Context

PowerShell does not require semicolons. Statements are separated by newlines. Despite this, semicolons appear frequently in PowerShell code written by developers coming from C#, JavaScript, or other C-family languages. They add visual noise and signal that the author is thinking in a different language.

### The two patterns

**Trailing semicolons** — line terminators left over from C# habits:

```powershell
# Wrong — semicolons are noise
$config = Get-Config;
$name = $config.Name;
Write-Message $name;
```

```powershell
# Correct
$config = Get-Config
$name = $config.Name
Write-Message $name
```

**Statement chaining on a single line** — permitted when it improves readability for short, related statements:

```powershell
# OK — short related assignments chained on one line
$inner = $Width - 2; "╰$('─' * $inner)╯"

# OK — compact switch branches
'Curved' { $inner = $Width - 2; "╰$('─' * $inner)╯" }
```

```powershell
# Wrong — trailing semicolons (statement terminators, not chaining)
$a = 1;
$b = 2;
```

The distinction: a semicolon followed by another statement on the same line is chaining (allowed). A semicolon at the end of a line is a trailing terminator (forbidden).

### The two exceptions

**`for` loop headers** — The `for` statement uses semicolons as syntactic separators. This is required — there is no alternative syntax:

```powershell
for ($i = 0; $i -lt 10; $i++) {
    # ...
}
```

**Inline hash table literals** — Semicolons separate entries in single-line hash tables. This is idiomatic PowerShell:

```powershell
$obj = [PSCustomObject]@{ Name = 'test'; Value = 42 }
```

Multi-line hash tables use newlines instead and do not need semicolons:

```powershell
$obj = [PSCustomObject]@{
    Name  = 'test'
    Value = 42
}
```

Both exceptions are structural — the semicolons serve as syntactic separators, not statement terminators.

## Decision

Never use semicolons as trailing statement terminators. Semicolons are permitted for chaining statements on a single line, in `for` loop headers, and in inline hash table literals.

### Rules

- **No trailing semicolons.** Statements end at the newline. A semicolon at the end of a line with nothing after it is dead syntax — a habit from C#/dotnet that does not belong in PowerShell.

- **Single-line chaining is allowed.** `$x = 1; $y = 2` on one line is fine — the semicolon chains two statements. The guard is against `.NET habits` where every line ends with `;`, not against concise single-line expressions.

- **`for` loop headers are exempt.** `for ($i = 0; $i -lt $n; $i++)` requires semicolons.

- **Inline hash table literals are exempt.** `@{ A = 1; B = 2 }` is idiomatic PowerShell.

### How this is enforced

- **PSScriptAnalyzer built-in rule `PSAvoidSemicolonsAsLineTerminators`** — catches trailing semicolons (already enabled).
- **PSScriptAnalyzer custom rule `Measure-NoSemicolons`** (severity: Error) — catches trailing semicolons (semicolons where the next token is on a different line). Allows single-line chaining, `for` headers, and hash tables.

## Consequences

- Code reads as idiomatic PowerShell, not transliterated C#.
- Every statement is on its own line — easier to read, debug, blame, and diff.
- Developers with C# habits get immediate feedback from the linter rather than accumulating semicolons over time.
- The `for` loop exception is narrow and unambiguous — no judgment calls needed.
