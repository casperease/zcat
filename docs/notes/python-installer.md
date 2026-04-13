PS C:\projects\zcat> install-devBoxTools
[Get-ToolsStatus] Getting status of tools
[Get-ToolsStatus] PySpark missing, NodeJs missing, Poetry missing, Python wrong version, Dotnet usable, Java missing, Terraform missing, AzCli wrong version
[Install-DevBoxTools] Skipping Dotnet — 10.0.201 already installed, not managed by tools system
[Invoke-CliCommand] winget install --id OpenJS.NodeJS.22 --scope user --accept-source-agreements --accept-package-agreements --silent --force
Found Node.js 22 [OpenJS.NodeJS.22] Version 22.22.2
This application is licensed to you by its owner.
Microsoft is not responsible for, nor does it grant any licenses to, third-party packages.
Successfully verified installer hash
Extracting archive...
Successfully extracted archive
Starting package install...
Path environment variable modified; restart your shell to use the new value.
Command line alias added: "node"
Successfully installed
NodeJs 22.22.2 installed successfully
Exception: C:\projects\zcat\automation\Zcat.Tools\private\Install-Tool.ps1:48
Line |
  48 |              throw "$Tool version mismatch: expected $Version.x, found …
     |              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Python version mismatch: expected 3.11.x, found was not found; run without arguments to install from the Microsoft Store, or disable this shortcut from Settings > Apps > Advanced app settings > App execution aliases. at
     | 'C:\Users\w83868\AppData\Local\Microsoft\WindowsApps\python.exe'. Run Install-Python -Force to replace, or uninstall manually.
────────────────────────────────────────────────────────────
at Install-Tool, C:\projects\zcat\automation\Zcat.Tools\private\Install-Tool.ps1: line 48
at Install-Python, C:\projects\zcat\automation\Zcat.Tools\Install-Python.ps1: line 35
at Install-DevBoxTools, C:\projects\zcat\automation\Zcat.Tools\Install-DevBoxTools.ps1: line 47
at install-devBoxTools
PS C:\projects\zcat> install-python -force
Exception: C:\projects\zcat\automation\Zcat.Tools\private\Uninstall-Tool.ps1:34
Line |
  34 |          throw "$Tool at '$location' was not installed by the expected …
     |          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Python at 'C:\Users\w83868\AppData\Local\Microsoft\WindowsApps\python.exe' was not installed by the expected package manager. Use Remove-Python to handle it.
────────────────────────────────────────────────────────────
at Uninstall-Tool, C:\projects\zcat\automation\Zcat.Tools\private\Uninstall-Tool.ps1: line 34
at Install-Tool, C:\projects\zcat\automation\Zcat.Tools\private\Install-Tool.ps1: line 45
at Install-Python, C:\projects\zcat\automation\Zcat.Tools\Install-Python.ps1: line 35
at install-python -force
