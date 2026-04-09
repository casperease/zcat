# ADR: Must be cross-platform

## Context

Our workstations run Windows, maybe MacOS, maybe Linux. Our CI runs Linux.
MacOs is a unix based os, so is linux, so we can reduce to Windows and Linux for most.
Everything we write must work on both — and a developer must be able to test locally everything that runs in CI.

PowerShell 7+ is cross-platform by design, but the _code_ people write in it often is not.
It is easy to accidentally use Windows-only cmdlets, .NET types that do not exist on Linux, backslash path separators,
registry access, COM objects, or shell-outs to `cmd.exe`. These work fine on the author's machine and fail silently or loudly in CI.

The usual response is "it works in CI, we'll fix it if it breaks." This is backwards.
A developer should never have to push to CI to discover a platform bug.
If you can run it locally, you can debug it locally — fast feedback, no waiting for pipeline queues.

### What breaks in practice

| Windows-ism                                            | Fails on Unix because                 |
| ------------------------------------------------------ | ------------------------------------- |
| `C:\path\to\file` hardcoded                            | No `C:` drive, no backslash paths     |
| `[Microsoft.Win32.Registry]`                           | Type does not exist on .NET Core Unix |
| `Get-Service`, `Get-WmiObject`                         | Cmdlets not available on Unix         |
| `cmd /c` or `Start-Process notepad`                    | Binaries do not exist                 |
| `$env:APPDATA`, `$env:USERPROFILE`                     | Variables not set on Unix             |
| `[System.IO.Path]::DirectorySeparatorChar` assumed `\` | It is `/` on Unix                     |
| Case-insensitive file lookups                          | Unix filesystems are case-sensitive   |

### What breaks the other way

| Unix-ism                                              | Fails on Windows because                     |
| ----------------------------------------------------- | -------------------------------------------- |
| `#!/usr/bin/env pwsh` shebang relied on for execution | Windows uses file associations, not shebangs |
| `chmod +x` permissions                                | NTFS does not have executable bits           |
| `/tmp`, `/dev/null` in paths                          | Not valid Windows paths                      |
| `apt-get`, `brew` assumed available                   | Windows uses `winget`                        |

### How we enforce this

**PSScriptAnalyzer** validates cmdlets and types against both Windows and Linux profiles at analysis time.
The settings file includes both targets:

```powershell
PSUseCompatibleCmdlets = @{
    compatibility = @(
        'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
        'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
    )
}

PSUseCompatibleTypes = @{
    TargetProfiles = @(
        'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
        'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
    )
}
```

This catches Windows-only cmdlets and .NET types _before the code runs_ — in the L2 test suite, on every developer's machine.

**Why no macOS profile?** PSScriptAnalyzer's built-in compatibility catalog only ships with Windows and Ubuntu profiles — there is no macOS catalog.
In practice this is fine: macOS and Linux both run .NET on Unix, so the cmdlet and type surface is nearly identical.
The Ubuntu profile effectively covers macOS. If Microsoft ever ships a macOS catalog, we add it to the list.

**Platform-aware installers** (see [controlling-systemwide-deps](controlling-systemwide-deps.md)) abstract package manager differences.
`Install-Python` calls `winget` on Windows and `apt-get` on Linux. The caller never writes platform-specific install logic.

**`Join-Path` and `[IO.Path]::Combine`** handle separators correctly on both platforms.
Hardcoded `/` or `\` in paths is always wrong.

## Decision

All automation code must run on both Windows and Linux.
Developers must be able to test locally on Windows/MacOS everything that runs in CI on Linux.

### Rules

- **Use `Join-Path` for all path construction.** Never concatenate strings with `/` or `\`.
  `Join-Path` uses the correct separator for the current platform.

- **Never use platform-specific cmdlets without a cross-platform alternative.**
  If a cmdlet only exists on Windows (e.g., `Get-Service`, `Get-WmiObject`), do not use it.
  If the operation genuinely requires platform-specific behavior, gate it with `$IsWindows` / `$IsLinux`
  and provide an implementation for both.

- **Never hardcode platform-specific paths.** No `C:\`, no `/tmp/`, no `$env:APPDATA`.
  Use `$env:RepositoryRoot`, `$PSScriptRoot`, `[IO.Path]::GetTempPath()`, or `Join-Path` from a known anchor.

- **Never shell out to platform-specific binaries.** No `cmd /c`, no `/bin/sh -c`.
  Use PowerShell native operations or the `Invoke-Executable` wrapper with tools that exist on both platforms.

- **Platform-specific logic uses `$IsWindows` / `$IsLinux` guards.**
  When platform-specific behavior is unavoidable (e.g., package manager selection in `Install-*` functions),
  use the built-in `$IsWindows` and `$IsLinux` automatic variables. Always provide both branches.

- **File operations must respect case sensitivity.** Linux filesystems are case-sensitive.
  `Get-ChildItem` with `-Filter '*.ps1'` works, but string-comparing filenames with `-eq` does not account for case.
  Use `-ieq` when comparing paths, or better, compare `[IO.Path]::GetFullPath()` results.

- **CI and local use the same code path.** This is reinforced from [controlling-systemwide-deps](controlling-systemwide-deps.md):
  the same `Install-WorkstationTools` and `importer.ps1` run on developer workstations and in CI pipelines.
  No separate scripts, no "CI-only" logic branches.

### How this is enforced

- **`PSUseCompatibleCmdlets`** — PSScriptAnalyzer rule that flags cmdlets not available on all target platforms.
  Runs in the L2 test suite against both Windows and Ubuntu profiles.

- **`PSUseCompatibleTypes`** — PSScriptAnalyzer rule that flags .NET types not available on all target platforms.
  Same dual-profile configuration.

- **L2 tests run locally.** Developers run the same `Test-ScriptAnalyzer.Tests.ps1` suite that CI runs.
  Platform compatibility violations are caught before push, not after.

## Consequences

- Code that passes L2 tests locally on Windows is validated against Linux compatibility without needing a Linux machine.
- CI failures caused by platform-specific code are caught before push, not in the pipeline queue.
- Developers can debug any CI issue locally because the code paths are identical.
- Platform-specific concerns are isolated to `Install-*` functions and gated with `$IsWindows` / `$IsLinux`.
  The rest of the codebase is platform-agnostic.
- Path handling is consistent everywhere — `Join-Path` is the only way to build paths.
- New platforms (macOS) can be added by extending the `Install-*` functions without touching business logic.
