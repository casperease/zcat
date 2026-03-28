# ADR: State-changing functions must be idempotent

## Context

Automation code gets re-run. Scripts crash halfway and get restarted. CI pipelines retry failed stages.
Developers run `Install-DevBox` after pulling changes even though half the tools are already installed.
A colleague runs a setup script not knowing someone already ran it on the shared build agent.

If state-changing functions are not idempotent, re-runs cause one of three problems:

1. **Failure on duplicate.** `New-AzResourceGroup` throws because the group already exists. The script stops,
the user has to figure out whether to delete and retry or skip and continue. A five-minute setup becomes a thirty-minute debugging session.

2. **Silent duplication.** `Add-DnsRecord` adds a second identical record. Nothing fails,
but the system now has duplicate state that causes subtle issues later — intermittent DNS resolution to the wrong IP,
duplicate entries in config files, double-charged resources.

3. **Inconsistent state.** `Set-Config` writes a file, but the function also creates a directory. On re-run the directory creation succeeds (already exists) but the file write uses different defaults because the function assumed it was starting from scratch.
The system is now in a state that no single run would produce.

Idempotent functions eliminate all three. Running them once or five times produces the same system state. Re-runs are always safe.

### What idempotent means in practice

A function is idempotent when calling it N times with the same arguments leaves the system in the same state as calling it once.
The function may do work on the first call and skip it on subsequent calls,
or it may overwrite the same state each time — either approach is valid as long as the end state is identical.

```powershell
# IDEMPOTENT — checks before acting
function Install-Poetry {
    $config = Get-ToolConfig -Tool 'Poetry'
    if (Test-Command $config.Command) {
        # Already installed — verify version and return
        Assert-ToolVersion -Tool 'Poetry'
        return
    }
    Invoke-Pip "install $($config.PipPackage)==$($config.Version).*"
    Assert-Command $config.Command
}

# IDEMPOTENT — overwrites to desired state regardless of current state
function Set-ProjectConfig {
    $config = @{ Version = $Version; Environment = $Environment }
    Set-Content -Path $ConfigPath -Value ($config | ConvertTo-Json)
}

# NOT IDEMPOTENT — appends on every call
function Set-ProjectConfig {
    Add-Content -Path $LogPath -Value "configured at $(Get-Date)"
    Set-Content -Path $ConfigPath -Value ($config | ConvertTo-Json)
}

# NOT IDEMPOTENT — fails if already exists
function New-ServicePrincipal {
    az ad sp create --id $AppId    # throws if SP already exists
}

# IDEMPOTENT — checks existence first
function New-ServicePrincipal {
    $existing = az ad sp show --id $AppId 2>$null | ConvertFrom-Json
    if ($existing) { return $existing }
    az ad sp create --id $AppId | ConvertFrom-Json
}
```

### Which functions this applies to

| Category                  | Idempotent?  | Why                                                             |
| ------------------------- | ------------ | --------------------------------------------------------------- |
| `Install-*`               | **Must be**  | Re-running setup is the most common scenario                    |
| `Set-*`, `Update-*`       | **Must be**  | Writing the same desired state twice must not corrupt           |
| `New-*`                   | **Must be**  | Must check existence before creating; return existing if found  |
| `Remove-*`, `Uninstall-*` | **Must be**  | Removing something already gone must not throw                  |
| `Assert-*`, `Test-*`      | Naturally    | Pure checks, no state change                                    |
| `Get-*`                   | Naturally    | Read-only, no state change                                      |
| `Write-*`                 | Not required | Output/logging functions produce output on every call by design |

**A note on `Invoke-*` wrappers.** The thin wrappers themselves (`Invoke-CliCommand`, `Invoke-Python`, `Invoke-Poetry`) are transparent pass-throughs — they do not control what the underlying command does,
so they cannot guarantee idempotency on their own. The calling function is responsible for ensuring idempotency — but that does not always mean adding extra checks.
If the underlying tool already guarantees idempotency (winget skips already-installed packages, `Set-Content` overwrites to the same result),
lean on that contract instead of adding redundant guards. Know the tools you wrap — unnecessary checks are waste, not safety.

### Common patterns for achieving idempotency

**Check-then-act.** Query the current state, compare to desired state, only act if they differ.
This is the most common pattern for `Install-*` and `New-*` functions.

**Overwrite to desired state.** Do not read current state — just write the desired state unconditionally. This is simpler and avoids race conditions.
Works well for `Set-*` functions that write files or set configuration values.

**Upsert.** Use APIs that support create-or-update semantics. Many Azure and cloud APIs have upsert endpoints or `--only-show-errors` flags that suppress "already exists" errors.
Prefer these over separate check-then-create logic when available.

**Guard clause with early return.** At the top of the function, check whether the desired state already exists and return immediately if so.
This is the simplest pattern and makes the idempotency visible in the first few lines.

```powershell
function Install-Tool {
    # Guard: already installed at the right version? Done.
    if ((Test-Command $config.Command) -and (Test-ToolVersion $Tool)) {
        return
    }
    # ... actual installation logic ...
}
```

## Decision

All state-changing functions (`Install-*`, `Set-*`, `New-*`, `Remove-*`, `Update-*`) must be idempotent.
Running them multiple times with the same arguments must produce the same system state as running them once.

### Rules

- **Check before acting.** Before creating, installing, or modifying, check whether the desired state already exists.
If it does, return early or silently succeed.

- **Never fail on "already exists" or "already removed".** These are success conditions for idempotent functions, not errors.
Handle them with a guard clause, not a try/catch.

- **Prefer overwrite over append.** Use `Set-Content` not `Add-Content`. Use `PUT` not `POST`.
Use create-or-update APIs over create-only APIs. Appending is inherently non-idempotent.

- **Return the resulting state.** Idempotent functions should return the same result regardless of whether they did work or short-circuited.
If `New-ServicePrincipal` creates a new SP, it returns the SP object. If the SP already existed, it returns that same object.

- **Document the idempotency contract.** If a function is idempotent, its comment-based help should say so.
If a function wraps a non-idempotent external command, that should also be noted.

## Consequences

- Scripts can be safely re-run after partial failures without cleanup.
- CI pipeline retries work without manual intervention.
- `Install-DevBox` can be run on every shell startup or after every pull without wasting time or breaking state.
- Setup instructions simplify to "run this script" — no "but only if you haven't already" caveats.
- Functions become more predictable: same inputs always produce the same system state, regardless of starting state.
