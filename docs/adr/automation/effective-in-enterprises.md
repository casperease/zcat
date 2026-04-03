# ADR: Effective in enterprise environments

## Context

Enterprise environments impose constraints that developer-oriented tooling rarely accounts for:

- **Home folders on network storage.** Central IT redirects `$HOME` or the Documents folder to DFS, mapped network drives, or OneDrive for Business (Known Folder Move).
  This means any operation that touches `$HOME\Documents\PowerShell\` — module discovery, profile loading, tab completion — traverses the network.
  On a bad day this adds seconds per operation. On a DFS failover day it hangs indefinitely.

- **No local admin.** Developers cannot install software, modify system paths, or change Group Policy settings.
  The automation must work within the permissions they have.

- **No container runtime.** Docker Desktop requires a license and local admin. Many enterprise machines do not have it.
  The automation cannot depend on containers (see [controlling-systemwide-deps](controlling-systemwide-deps.md)).

- **Locked-down PSModulePath.** Group Policy or login scripts may add network paths to `$env:PSModulePath`.
  PowerShell scans every path on module auto-load, tab completion, and `Get-Module -ListAvailable`.
  Network paths in this list are the primary cause of "PowerShell is slow" in enterprises.

- **Proxy and firewall.** Gallery access (`Install-Module`, `Find-Module`) may be blocked or require proxy configuration.
  Operations that need the network at runtime are unreliable.

### The specific problem: PSModulePath

PowerShell's default `$env:PSModulePath` includes:

```text
$HOME\Documents\PowerShell\Modules     ← user profile (NETWORK)
C:\Program Files\PowerShell\Modules    ← system-wide PS 7 (local)
$PSHOME\Modules                        ← pwsh built-in (local)
```

The first entry is the killer. Every time PowerShell auto-loads a module, resolves a command, or offers tab completion, it scans this path.
When it points to a network share, each scan is a network round-trip. With DFS, it can be multiple round-trips through namespace resolution.

We vendor all dependencies. The user profile module path is never needed.

## Decision

The importer rebuilds `$env:PSModulePath` from scratch, keeping only local system paths.
Network paths, user profile paths, and any other non-local entries are stripped before anything loads.

### What the importer does

```powershell
$env:PSModulePath = @(
    "$PSHOME/Modules"                           # pwsh built-in
    "$ProgramFiles/PowerShell/Modules"          # system-wide PS 7
    "$SystemRoot/.../WindowsPowerShell/Modules"  # Windows built-in (Windows only)
    "$ProgramFiles/WindowsPowerShell/Modules"    # system-wide PS 5.1 (Windows only)
) -join [IO.Path]::PathSeparator
```

The vendor loader adds the `.vendor` path later. No user profile path is ever included.

### Rules

- **Never add network paths to PSModulePath.** If a module is needed, vendor it.
  If it cannot be vendored (Az modules), it must be installed locally by the environment (see [prefer-az-cli](prefer-az-cli.md)).

- **Never depend on the user profile.** No function may read from or write to `$HOME\Documents\PowerShell\`.
  Profiles are the user's concern, not the automation's.

- **Never call the PowerShell Gallery at runtime.** `Install-Module` and `Find-Module` require network access and gallery availability.
  All module dependencies are vendored (see [vendor-toolset-dependencies](vendor-toolset-dependencies.md)).

- **Assume no local admin.** Tool installers use `winget` (which works without admin for per-user installs), `brew`, or `apt-get`.
  Functions must not require elevated privileges unless explicitly documented.

### How this is enforced

- **`importer.ps1`** — rebuilds `$env:PSModulePath` as the first operation, before any module is loaded.
- **Vendoring** — all module dependencies are checked into `.vendor/`, eliminating gallery access at runtime.
- **`Install-VendorModule`** — the only supported way to add modules, runs once at authoring time, not at runtime.

## Consequences

- The importer starts fast regardless of where `$HOME` points. No network scanning, no DFS resolution, no OneDrive sync delays.
- Tab completion is instant — PowerShell only scans local paths.
- The automation works behind firewalls and proxies with no gallery access.
- Users who have personal modules in their profile path will not see them in sessions that dot-source the importer. This is intentional — the automation session is self-contained.
- System-installed modules (in Program Files) remain available. Only the user profile path is removed.
