<#
.SYNOPSIS
    Provisions the development environment with all required tools.
.DESCRIPTION
    Installs all locked tool versions. Idempotent — safe to run
    repeatedly. Skips tools that are already installed at the correct
    version.
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

    # Preflight: detect tools not managed by the expected package manager.
    # Wrong version + other manager: Install-DevBox cannot uninstall these.
    # Right version + other manager: works today, but the other manager can
    # silently upgrade and break things later. Catch it now.
    $status = Get-DevBoxStatus
    $blockers = @($status | Where-Object { $_.Manager -eq 'other' })

    if ($blockers) {
        $details = ($blockers | ForEach-Object {
            "  $($_.Tool) $($_.Installed) at '$($_.Location)' — $($_.Action)"
        }) -join "`n"
        throw "Install-DevBox cannot proceed. These tools must be removed manually first:`n`n$details"
    }

    Install-Python -Force:$Force
    Install-Poetry
    Install-Dotnet -Force:$Force
    Install-AzCli -Force:$Force
}
