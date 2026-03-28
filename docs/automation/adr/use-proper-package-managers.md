# ADR: Use proper package managers

## Context

System-wide tools are installed by platform-native package managers (see [controlling-systemwide-deps](controlling-systemwide-deps.md)).
On Windows, the choice of package manager matters because not all options carry the same security properties.

### Chocolatey's security model is structurally weak

Chocolatey installs packages by downloading and executing PowerShell scripts as administrator.
Both the package script (`chocolateyInstall.ps1`) and the installer it fetches are attack surface — effectively doubling the vectors compared to a manager that only runs signed installers.

Specific problems:

1. **Arbitrary script execution.** Every Chocolatey install runs community-authored PowerShell as SYSTEM.
   There is no sandboxing, no code signing by default, and no process isolation between the package script and the host.

2. **Community repository trust.** The public Chocolatey repository accepts submissions from anyone.
   Moderation exists but has lag — packages are live before human review completes.
   Chocolatey themselves state the community repository is [not recommended for organizational use](https://docs.chocolatey.org/en-us/information/security/).

3. **Abuse in the wild.** Chocolatey has been used as a malware delivery vector.
   The [Serpent backdoor campaign](https://www.bleepingcomputer.com/news/security/serpent-malware-campaign-abuses-chocolatey-windows-package-manager/) targeted French government agencies and construction firms by abusing Chocolatey specifically because it is commonly whitelisted in enterprise environments.

4. **Known vulnerabilities.** CVE-2022-29953 and CVE-2022-29954 exposed local privilege escalation in Chocolatey Agent (licensed edition), patched in 1.1.1+.

5. **Insecure default install path.** If Chocolatey is installed to the system drive root, any local user gains an attack vector.

Chocolatey for Business mitigates some of these issues with internal repositories, package internalization, and runtime malware scanning — but that is a paid product, and none of those controls exist in the free tier that most setups use.

### Winget is structurally more secure

Winget ships with Windows 11 and Windows 10 (via App Installer). It is the first-party Microsoft package manager.

- **Hash-verified installers.** Every manifest in the `winget-pkgs` repository requires a SHA256 hash. Winget downloads standard installer formats (MSI, MSIX, EXE) and verifies the hash before execution. No arbitrary script execution.

- **Mandatory review.** Every submission undergoes automated malware scanning and moderator review before approval. Packages are not available until review completes.

- **Microsoft Store integration.** MSIX packages from the Store source are signed and sandboxed, providing an additional trust layer.

- **No additional trust boundary.** Winget is a Windows component. There is no third-party runtime to install, trust, or whitelist.

### Other platforms

macOS uses Homebrew (`brew`), Linux uses apt-get. These are the established platform-native managers and are not affected by this decision.

## Decision

Windows tool installation uses `winget`. Chocolatey is not used.

### Rules

- **Use `winget` for all Windows package installations.** Every tool entry in `config/tools.yml` specifies a `WingetId`. There is no `ChocolateyId` field.

- **Do not introduce Chocolatey as a dependency.** No function should shell out to `choco`, reference a Chocolatey package, or assume Chocolatey is installed.

- **Remove Chocolatey from target machines.** `Uninstall-Chocolatey` removes the Chocolatey installation, its environment variables, and its PATH entries. It is idempotent — safe to run when Chocolatey is not present. `Install-DevBox` calls it as its first step so that environments previously provisioned with Chocolatey are cleaned up automatically.

- **`Get-DevBoxStatus` reports Chocolatey as unwanted.** If `choco` is on PATH, the status output includes a Chocolatey entry with status `Unwanted` and the recommended action `Run Uninstall-Chocolatey`.

- **Continue using platform-native managers on other platforms.** `brew` on macOS, `apt-get` on Linux. This ADR only constrains the Windows choice.

- **Verify hashes when winget does not.** If a tool is installed outside winget (direct download), the `Install-*` function must verify a checksum. Never trust an unsigned, unverified binary.

## Consequences

- Windows installations use the same trust model as the OS itself — Microsoft-moderated, hash-verified, no arbitrary script execution.
- The attack surface from package installation is reduced to signed installer formats rather than arbitrary PowerShell.
- Tools not yet available in the winget repository must be installed via direct download with checksum verification, or the team must submit a winget manifest upstream.
- Machines that previously used Chocolatey are cleaned up automatically by `Install-DevBox`. No manual intervention required.
