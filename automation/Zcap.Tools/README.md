# Zcap.Tools

CLI tool management with version locking, idempotent installation, and cross-platform support.

## Quick start

```powershell
Install-DevBox                  # install all tools at locked versions
Install-DevBox -Force           # replace wrong versions automatically
Install-DevBox -AcceptExisting  # accept correct-version tools regardless of scope/manager
```

## Tools

Each tool has `Install-`, `Invoke-`, and `Uninstall-` functions. Versions are locked in `config/tools.yml`.

| Tool      | Command  | Functions                                             |
| --------- | -------- | ----------------------------------------------------- |
| Python    | `python` | `Install-Python`, `Invoke-Python`, `Uninstall-Python` |
| Poetry    | `poetry` | `Install-Poetry`, `Invoke-Poetry`, `Uninstall-Poetry` |
| .NET SDK  | `dotnet` | `Install-Dotnet`, `Invoke-Dotnet`, `Uninstall-Dotnet` |
| Azure CLI | `az`     | `Install-AzCli`, `Invoke-AzCli`, `Uninstall-AzCli`    |

### Azure CLI extras

```powershell
Connect-AzCli                        # interactive browser login
Connect-AzCli -DeviceCode            # headless / SSH
Connect-AzCli -ServicePrincipal ...  # CI / automation
Connect-AzCli -ManagedIdentity       # Azure-hosted
Disconnect-AzCli
Set-AzCliSubscription 'my-sub'
```

All Az functions are idempotent — `Connect-AzCli` skips if already authenticated (validates tenant + app ID for service principal), `Set-AzCliSubscription` skips if already on the correct subscription.

## How it works

`Invoke-*` functions assert the installed version matches `config/tools.yml` before every execution (checked once per session, cached). `Install-*` functions skip if the correct version is already on PATH. With `-Force`, wrong versions are uninstalled first.

### User-space installation

Tools prefer user-space installation to avoid admin requirements. The installation method for each tool is determined by config fields in `tools.yml`:

| Config field          | Mechanism                                                              |
| --------------------- | ---------------------------------------------------------------------- |
| `WingetId`            | winget (Windows). `WingetScope: user` adds `--scope user`.            |
| `BrewFormula`         | Homebrew (macOS, always user-space).                                   |
| `AptPackage`          | apt-get (Linux, requires root — asserted up front).                    |
| `PipPackage`          | pip (cross-platform, user-space). Used as fallback on Windows/Linux.   |
| `UserInstallDir`      | Vendored install script (no package manager). User-space on all platforms. |
| `WindowsInstallRoot`  | Overrides `$HOME` as base for `UserInstallDir` on Windows (avoids OneDrive). |

A tool may have multiple fields (e.g., `BrewFormula` for macOS + `PipPackage` for Windows/Linux). The most specific match for the current platform wins.

### Scope enforcement

By default, `Install-DevBox` blocks tools installed machine-wide or by an unexpected manager. Use `-AcceptExisting` to relax this — accepting any correct-version install regardless of scope or manager.

`Get-DevBoxStatus` reports each tool's `Status`, `Manager`, and `Scope` for diagnostics.

## Adding a new tool

1. Add an entry to `config/tools.yml` with version, command, platform-specific package IDs, and version detection pattern.
2. Create `Install-<Tool>.ps1`, `Invoke-<Tool>.ps1`, `Uninstall-<Tool>.ps1`.
3. Add to `Install-DevBox`.
4. For tools that need vendored install scripts, place them in `scripts/`.

## Enterprise / air-gapped environments

For environments behind a corporate proxy or without public internet:

| Manager      | Artifactory support | Notes                                                                                                                                              |
| ------------ | ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **apt-get**  | Full, native        | Debian repo type (local/remote/virtual). First-class Artifactory feature.                                                                          |
| **Homebrew** | Partial             | Bottle caching via Generic/Docker repo + `HOMEBREW_BOTTLE_DOMAIN`. Taps (formulas) still need a Git server.                                        |
| **winget**   | None                | No Artifactory integration. Winget requires its own REST source interface. Store installers in a Generic repo and use direct URLs as a workaround. |

For winget in locked-down environments, consider pre-installing tools in the base image or using a private winget REST source.
