# Zcap.Tools

CLI tool management with version locking, idempotent installation, and cross-platform support.

## Quick start

```powershell
Install-DevBox          # install all tools at locked versions
Install-DevBox -Force   # replace wrong versions automatically
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

## Platform package managers

Installation uses the native package manager per platform:

| Platform | Manager  | Config key    |
| -------- | -------- | ------------- |
| Windows  | winget   | `WingetId`    |
| macOS    | Homebrew | `BrewFormula` |
| Linux    | apt-get  | `AptPackage`  |

Poetry is the exception — installed via pip on all platforms.

## Adding a new tool

1. Add an entry to `config/tools.yml`:

    ```yaml
    Terraform:
        Version: "1.9"
        Command: terraform
        WingetId: "Hashicorp.Terraform"
        BrewFormula: "terraform"
        AptPackage: "terraform"
        VersionCommand: "terraform --version"
        VersionPattern: "^Terraform v(?<ver>.+)$"
    ```

2. Create `Install-Terraform.ps1`, `Invoke-Terraform.ps1`, `Uninstall-Terraform.ps1`
3. Add to `Install-DevBox`

## Enterprise / air-gapped environments

For environments behind a corporate proxy or without public internet:

| Manager      | Artifactory support | Notes                                                                                                                                              |
| ------------ | ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **apt-get**  | Full, native        | Debian repo type (local/remote/virtual). First-class Artifactory feature.                                                                          |
| **Homebrew** | Partial             | Bottle caching via Generic/Docker repo + `HOMEBREW_BOTTLE_DOMAIN`. Taps (formulas) still need a Git server.                                        |
| **winget**   | None                | No Artifactory integration. Winget requires its own REST source interface. Store installers in a Generic repo and use direct URLs as a workaround. |

For winget in locked-down environments, consider pre-installing tools in the base image or using a private winget REST source.
