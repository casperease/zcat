# ADR: Sensible defaults for all parameters

## Status

Accepted

## Context

Automation functions should be easy to call. If a function requires five
parameters to do the most common thing, nobody will use it — they will
write their own inline version or skip automation entirely. The most
common invocation of any function should require zero or minimal
arguments.

PowerShell makes this easy: parameters can have default values, can pull
from configuration, and can be positional. But it requires discipline to
design every function with the "just call it" experience in mind.

### What sensible defaults look like

```powershell
# GOOD — most common case needs zero arguments
Install-Poetry                              # installs locked version
Install-Poetry -Version '2.2'              # overrides only when needed

# BAD — caller must always specify version
Install-Poetry -Version '2.1'              # no default, mandatory every time
```

```powershell
# GOOD — reads from config, caller overrides if needed
function Install-Python {
    param([string] $Version)
    $config = Get-ToolConfig -Tool 'Python'
    if (-not $Version) { $Version = $config.Version }
    # ...
}

# BAD — caller must know the version
function Install-Python {
    param([Parameter(Mandatory)] [string] $Version)
    # ...
}
```

```powershell
# GOOD — positional for the primary argument, switches for behavior
Invoke-Poetry 'install'
Invoke-Poetry 'install' -PassThru

# BAD — named parameters for everything
Invoke-Poetry -Arguments 'install' -PassThru
```

### The principle

Every function should answer the question: **"What would the caller most
likely pass here?"** If there is a single obvious answer, that answer is
the default. If the answer comes from configuration, read it from config.
If the answer is "nothing" (the feature is off), use a `[switch]`.

This does not mean making everything optional. A function that does
nothing useful without a specific value should make that parameter
mandatory. `Invoke-Poetry` without arguments would enter an interactive
prompt — that is never the right default, so `$Arguments` is mandatory.
The test is: **does a reasonable default exist?** If yes, use it. If no,
make it mandatory.

### Where defaults come from

In order of preference:

1. **Configuration files.** Tool versions come from `config/tools.yml`.
   Environment settings come from `config/meta.yml`. The function reads
   config internally — the caller does not need to know where the value
   lives.

2. **Convention.** Output verbosity defaults to `Normal`. Test level
   defaults to `1`. These are values that are right 90% of the time.

3. **The environment.** `$env:RepositoryRoot` provides the repo root.
   `$PSScriptRoot` provides the script's own directory. The function
   uses these anchors instead of requiring a path parameter.

4. **Switches for opt-in behavior.** `-PassThru`, `-DryRun`, `-Silent`,
   `-NoAssert` — these are off by default because the common case does
   not need them. The caller opts in explicitly when needed.

## Decision

Every parameter must have a sensible default unless no reasonable default
exists. The most common invocation of any function should require zero or
minimal arguments.

### Rules

- **The zero-argument call must work.** If a function can do useful work
  without any input, all parameters should have defaults. `Install-Poetry`
  with no arguments installs the locked version. `Test-Automation` with no
  arguments runs L0 + L1 tests with normal output.

- **Pull defaults from configuration, not hardcoded values.** Tool
  versions, environment names, and other values that change over time
  come from config files. The function reads them internally. When the
  locked version changes, callers do not need to update.

- **Use positional parameters for the primary argument.** The most
  important parameter should be `Position = 0` so the caller can skip the
  parameter name. `Invoke-Poetry 'install'` reads better than
  `Invoke-Poetry -Arguments 'install'`.

- **Use switches for opt-in behavior.** Boolean flags that are off by
  default should be `[switch]`, not `[bool]`. Switches are self-documenting
  at the call site: `-PassThru` is clearer than `-PassThru $true`.

- **Make parameters mandatory only when no default makes sense.** If the
  function would do something wrong or meaningless without the value, it
  is mandatory. If the function can do the right thing with a derived
  value, derive it.

## Consequences

- Functions are easy to discover and try — just call them with no
  arguments and see what happens.
- Scripts are concise — only non-default values appear at the call site,
  making the intent clear.
- Configuration changes propagate automatically — updating a version in
  `tools.yml` updates every function that reads it, without touching
  call sites.
- New team members can use functions immediately without reading the help
  to find out what to pass.
