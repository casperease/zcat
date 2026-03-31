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

**Inline semicolons** — multiple statements crammed onto one line:

```powershell
# Wrong — hard to read, hard to debug, hard to set breakpoints on
$a = 1; $b = 2; $c = $a + $b

# Wrong — hides control flow
if ($failed) { Write-Message 'failed'; throw 'done' }
```

```powershell
# Correct — one statement per line
$a = 1
$b = 2
$c = $a + $b

if ($failed) {
    Write-Message 'failed'
    throw 'done'
}
```

Inline semicolons harm readability and debuggability. You cannot set a breakpoint on the second statement of `$a = 1; $b = 2`. In `git blame`, both statements share a single line, so you lose attribution granularity.

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

Never use semicolons as statement separators or line terminators. The only permitted semicolons are syntactic separators inside `for` loop headers and inline hash table literals.

### Rules

- **No trailing semicolons.** Statements end at the newline. A semicolon at the end of a line is dead syntax.

- **No inline semicolons between statements.** Put each statement on its own line. If a line has two statements separated by a semicolon, split it into two lines.

- **`for` loop headers are exempt.** `for ($i = 0; $i -lt $n; $i++)` requires semicolons.

- **Inline hash table literals are exempt.** `@{ A = 1; B = 2 }` is idiomatic PowerShell.

### How this is enforced

- **PSScriptAnalyzer built-in rule `PSAvoidSemicolonsAsLineTerminators`** — catches trailing semicolons (already enabled).
- **PSScriptAnalyzer custom rule `Measure-NoSemicolons`** (severity: Error) — catches all remaining semicolons except those inside `for` loop headers.

## Consequences

- Code reads as idiomatic PowerShell, not transliterated C#.
- Every statement is on its own line — easier to read, debug, blame, and diff.
- Developers with C# habits get immediate feedback from the linter rather than accumulating semicolons over time.
- The `for` loop exception is narrow and unambiguous — no judgment calls needed.
