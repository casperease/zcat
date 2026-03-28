# ADR: Avoid deep nesting in statements and expressions

## Context

PowerShell makes it easy to chain member access, method calls, indexing, pipelines, and subexpressions into a single line.
The result compiles and runs fine, but quickly becomes unreadable:

```powershell
# What does this do? You have to parse it inside-out to find out.
$name = (Get-Content $path | ConvertFrom-Json).Items.Where({ $_.Status -eq 'Active' })[0].Name.ToLower()
```

```powershell
# Conditional with buried logic — the reader must mentally evaluate the entire
# expression before understanding what the if-statement is actually testing.
if ((Get-ChildItem $path -Filter '*.ps1' -Recurse | Where-Object { $_.Length -gt 0 }).Count -gt 5) {
```

The same logic, split into named steps, reads top-to-bottom:

```powershell
$config  = Get-Content $path | ConvertFrom-Json
$active  = $config.Items.Where({ $_.Status -eq 'Active' })
$name    = $active[0].Name.ToLower()
```

```powershell
$scripts = Get-ChildItem $path -Filter '*.ps1' -Recurse | Where-Object { $_.Length -gt 0 }
if ($scripts.Count -gt 5) {
```

This is not about line length or aesthetics. Deep nesting has concrete costs for debugging, assertability, and code review.

### Why splitting has zero performance cost

PowerShell variables are references to .NET objects on the heap, not copies.
When you write `$config = Get-Content $path | ConvertFrom-Json`, the variable `$config` holds a pointer to the object that already exists in memory.
No data is duplicated. The only cost is the variable binding itself, which is a dictionary lookup — nanoseconds compared to the milliseconds the pipeline or method call takes.

This is true for strings, arrays, hashtables, and custom objects alike.
Splitting a deeply nested expression into three intermediate variables does not allocate three times the memory or run three times slower.
It runs the same operations in the same order and produces the same objects — the variables are just names for things that already exist.

### Why splitting makes debugging easier

When a deeply nested expression throws, the error points at the entire line:

```text
InvalidOperation: You cannot index into a null array.
At C:\projects\zcap\automation\Zcap.Tools\Install-Dotnet.ps1:42
```

Which part is null? The pipeline result? The `.Items` property? The `.Where()` output? The `[0]` index?
You cannot tell without attaching a debugger or adding temporary `Write-Host` calls — both slow and error-prone.

When each step is on its own line, the error points at the exact operation that failed:

```text
InvalidOperation: You cannot index into a null array.
At C:\projects\zcap\automation\Zcap.Tools\Install-Dotnet.ps1:44
```

Line 44 is `$name = $active[0].Name.ToLower()` — so `$active` is null or empty.
The previous line produced it. The diagnosis is immediate.

### Why splitting enables assertions

The [fail-fast-with-asserts](fail-fast-with-asserts.md) ADR establishes that roughly every fifth line should be an assertion.
You cannot assert intermediate values that do not exist as variables:

```powershell
# No way to assert that the JSON parsed correctly, that Items exists,
# or that the Where() found anything — it is all one expression.
$name = (Get-Content $path | ConvertFrom-Json).Items.Where({ $_.Status -eq 'Active' })[0].Name.ToLower()
```

Split into steps, you can inject assertions exactly where assumptions are made:

```powershell
$config = Get-Content $path | ConvertFrom-Json
Assert-HaveProperty $config 'Items'

$active = $config.Items.Where({ $_.Status -eq 'Active' })
Assert-PipelineCount $active -Minimum 1

$name = $active[0].Name.ToLower()
Assert-NotNullOrWhitespace $name
```

Each assertion documents a precondition and catches failures at the source.
Without the intermediate variables, these checks are impossible without restructuring the code anyway.

### When nesting is fine

Simple, well-known expressions that read naturally do not need splitting:

```powershell
# Fine — Join-Path is self-documenting and cannot fail in surprising ways
$settingsPath = Join-Path $env:RepositoryRoot 'PSScriptAnalyzerSettings.psd1'

# Fine — single property access on a known object
$moduleName = $moduleDir.Name

# Fine — short pipeline with one stage
$ps1Files = Get-ChildItem $path -Filter '*.ps1'
```

The rule of thumb: if you have to scan backwards or count parentheses to understand a line, split it.

## Decision

Prefer flat, step-by-step code over deeply nested expressions.
Assign intermediate results to descriptively named variables and use those variables on the next line.

### Rules

- **One operation per line.** A pipeline, a method call, or an indexing operation — pick one per assignment.
  Chaining two is often fine. Chaining three or more almost always needs splitting.

- **Name the intermediate result.** The variable name documents what the value represents.
  `$active` is more informative than the `.Where(...)` buried in a chain.

- **Assert between steps.** Once intermediate values have names, inject `Assert-*` calls
  to verify assumptions before the next step uses the value.

- **Conditionals get the same treatment.** Do not bury logic inside `if (...)`.
  Compute the value, optionally assert it, then test it.

- **Simple expressions are exempt.** `Join-Path`, single property access, straightforward casts,
  and other operations that cannot fail in surprising ways do not need their own line.

## Consequences

- Lines are shorter and each does one thing — code reviews can evaluate one step at a time.
- Error messages point at the exact operation that failed, not at a 200-character compound expression.
- Intermediate variables create natural injection points for `Assert-*` calls, supporting the fail-fast pattern.
- Variable names serve as documentation for what each intermediate value represents.
- No performance cost — variables are references, not copies.
- Slightly more lines of code, which is a worthwhile trade for readability, debuggability, and assertability.
