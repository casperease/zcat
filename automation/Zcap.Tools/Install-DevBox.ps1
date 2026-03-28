<#
.SYNOPSIS
    Provisions the development environment with all required tools.
.DESCRIPTION
    Installs all locked tool versions. Idempotent — safe to run
    repeatedly. Skips tools that are already installed at the correct
    version. Tools at the correct version but installed outside the
    expected manager are left untouched with a message.
.PARAMETER Force
    Replace existing installations that are at the wrong version.
.EXAMPLE
    Install-DevBox
.EXAMPLE
    Install-DevBox -Force
#>
function Install-DevBox {
    [CmdletBinding()]
    param(
        [switch] $Force
    )

    # Remove Chocolatey if present — this toolset uses winget on Windows.
    # See ADR: use-proper-package-managers.
    Uninstall-Chocolatey

    # Report tools that work but aren't managed by us — left untouched.
    $status = Get-DevBoxStatus
    $usable = @($status | Where-Object { $_.Status -eq 'Usable' })
    foreach ($tool in $usable) {
        Write-Message "Skipping $($tool.Tool) — $($tool.Installed) works, installed outside $($tool.Manager ?? 'expected manager')"
    }

    Install-Python -Force:$Force
    Install-Poetry
    Install-Dotnet -Force:$Force
    Install-AzCli -Force:$Force
}
