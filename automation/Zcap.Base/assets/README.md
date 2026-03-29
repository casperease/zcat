# Enterprise DFS Fix for PowerShell 7

## Problem

Enterprise GPOs redirect the Documents folder to a DFS/UNC share. PowerShell 7 derives its user module path from `Documents\PowerShell\Modules`, causing every module lookup, tab completion, and auto-load to recursively scan the network share. This manifests as "Searching for available modules [\\dfs\...]" progress bars and multi-second delays.

## Root cause

PS7 constructs `$env:PSModulePath` at startup by combining paths from multiple sources:

1. **User-scope config** (`Documents\PowerShell\powershell.config.json`) — if a `PSModulePath` key exists, use it as the CurrentUser module path. Otherwise derive from `Documents\PowerShell\Modules`.
2. **AllUsers config** (`$PSHOME\powershell.config.json`) — AllUsers module path.
3. **`$PSHOME\Modules`** — always included (core modules: PSReadLine, etc).

When Documents is on DFS, step 1 resolves to a UNC path. PS7 then recursively scans that network share on every module operation.

## Solution

`Set-LocalPSModulePath.ps1` writes a user-scope `powershell.config.json` that overrides the CurrentUser module path to a local directory. PS7 reads this single file at startup — one file read from DFS is fast, the slowness comes from recursive module scanning.

```powershell
& 'automation\Zcap.Base\assets\Set-LocalPSModulePath.ps1'
```

No admin required. Restart PowerShell after running.

The config file is placed at `Documents\PowerShell\powershell.config.json` (on DFS) and contains:

```json
{
    "PSModulePath": "C:\\Users\\<user>\\AppData\\Local\\PowerShell\\Modules"
}
```

The `$PROFILE` and config file remain on DFS — that's fine. PS7 hardcodes their location from `[Environment]::GetFolderPath('MyDocuments')` and there is no supported way to relocate them.

Single file reads are fast; the performance problem is exclusively from recursive module directory scanning.

## Detection

The importer (`importer.ps1`) checks `$env:PSModulePath` for UNC paths at startup and displays a warning with instructions if found.

## Verification

After running the script and restarting PowerShell:

```powershell
# No UNC paths
$env:PSModulePath -split [IO.Path]::PathSeparator

# Core modules discoverable
Get-Module Microsoft.PowerShell.Utility -ListAvailable

# Install-Module functional
Install-Module -Name SomeModule -WhatIf
```

## Approaches that don't work

| Approach                                                                      | Why it fails                                                                                                                                                                                                                                                                                                                                                                                                           |
| ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Runtime `$env:PSModulePath` strip**                                         | Removing UNC paths from `$env:PSModulePath` at runtime works momentarily, but PS7 internally reconstructs PSModulePath during certain operations. The WinCompat layer starts a background WinPS 5.1 process whose PSModulePath includes the DFS-based Documents path; when it completes, PS7 inherits those paths back. Module auto-loading can trigger the same reconstruction. The DFS path reappears unpredictably. |
| **Symlinks** (`Documents\PowerShell` → local dir)                             | Windows traces the symlink back to the network origin. Files accessed through the symlink are treated as "remote" by the `RemoteSigned` execution policy, blocking `$PROFILE` from loading.                                                                                                                                                                                                                            |
| **AllUsers config** (`$PSHOME\powershell.config.json` with `PSModulePath`)    | Sets the AllUsers module path, **not** the CurrentUser path. The DFS-based CurrentUser path remains. Worse, it overrides `$PSHOME\Modules`, removing core modules (PSReadLine, Microsoft.PowerShell.Utility, etc).                                                                                                                                                                                                     |
| **User-scope PSModulePath registry value** (`HKCU:\Environment\PSModulePath`) | PS7 detects the user-scoped env var differs from the process-inherited one and treats it as a full user override — it stops appending `$PSHOME\Modules`. Core modules become undiscoverable.                                                                                                                                                                                                                           |
| **`$PSModuleAutoLoadingPreference = 'None'`**                                 | Suppresses the network scanning symptom but breaks `Get-Module -ListAvailable`, `Get-Command` discovery, and any code relying on module auto-loading.                                                                                                                                                                                                                                                                  |
| **Removing base module imports from importer**                                | The three core modules (`Microsoft.PowerShell.Management`, `.Security`, `.Utility`) are auto-loaded by PS7. Explicitly importing them can trigger the WinCompat layer if old WinPS 5.1 versions are found on the path, producing warnings and re-adding DFS paths. Removing the imports fixes the warnings but doesn't fix the underlying PSModulePath issue.                                                          |
