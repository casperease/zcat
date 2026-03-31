<#
.SYNOPSIS
    Provisions the local development environment with all required tools.
.DESCRIPTION
    Installs all locked tool versions. Idempotent — safe to run
    repeatedly. Skips tools that are already installed at the correct
    version. Tools at the correct version but installed outside the
    expected manager are left untouched with a message.
.PARAMETER Force
    Replace existing installations that are at the wrong version.
.EXAMPLE
    Install-WorkstationTools
.EXAMPLE
    Install-WorkstationTools -Force
#>
function Install-WorkstationTools {
    [CmdletBinding()]
    param(
        [switch] $Force
    )

    # Remove Chocolatey if present — this toolset uses winget on Windows.
    # See ADR: use-proper-package-managers.
    Uninstall-Chocolatey

    # Report tools that work but aren't managed by us — left untouched.
    $status = Get-WorkstationToolsStatus
    $usable = @($status | Where-Object { $_.Status -eq 'Usable' })
    foreach ($tool in $usable) {
        Write-Message "Skipping $($tool.Tool) — $($tool.Installed) already installed, not managed by tools system"
    }

    # Foundation tools (no dependencies)
    Install-Python -Force:$Force
    Install-Java -Force:$Force
    Install-Dotnet -Force:$Force
    Install-NodeJs -Force:$Force

    # Pip-based tools (need Python)
    Install-Poetry
    Install-AzCli -Force:$Force
    Install-PySpark

    # Standalone CLI tools
    Install-Terraform -Force:$Force
}
