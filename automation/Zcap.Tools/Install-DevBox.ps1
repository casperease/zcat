<#
.SYNOPSIS
    Provisions the development environment with all required tools.
.DESCRIPTION
    Installs all locked tool versions. Idempotent — safe to run
    repeatedly. Skips tools that are already installed at the correct
    version and scope.
.PARAMETER Force
    Replace existing installations that are at the wrong version.
.PARAMETER AcceptExisting
    Accept correct-version tools regardless of install scope or manager.
    Without this, machine-wide installs and non-standard managers are
    blocked with a message.
.EXAMPLE
    Install-DevBox
.EXAMPLE
    Install-DevBox -Force
.EXAMPLE
    Install-DevBox -AcceptExisting
#>
function Install-DevBox {
    [CmdletBinding()]
    param(
        [switch] $Force,
        [switch] $AcceptExisting
    )

    # Remove Chocolatey if present — this toolset uses winget on Windows.
    # See ADR: use-proper-package-managers.
    Uninstall-Chocolatey

    # Preflight: detect tools that would block installation.
    $status = Get-DevBoxStatus

    if ($AcceptExisting) {
        # Only block on wrong-version + other-manager (can't auto-fix — we don't
        # know how to uninstall). Everything else is accepted as-is.
        $blockers = @($status | Where-Object {
            $_.Status -eq 'WrongVersion' -and $_.Manager -eq 'other'
        })
    }
    else {
        # Block on tools managed by an unexpected manager. Scope is not a
        # blocker — if the right version is managed by our package manager,
        # it works regardless of whether it's user-space or machine-wide.
        $blockers = @($status | Where-Object { $_.Manager -eq 'other' })
    }

    if ($blockers) {
        $details = ($blockers | ForEach-Object {
            "  $($_.Tool) $($_.Installed) at '$($_.Location)' [$($_.Manager), $($_.Scope)] — $($_.Action)"
        }) -join "`n"
        throw "Install-DevBox cannot proceed. Use -AcceptExisting to allow correct-version tools regardless of scope/manager.`n`n$details"
    }

    Install-Python -Force:$Force
    Install-Poetry
    Install-Dotnet -Force:$Force
    Install-AzCli -Force:$Force
}
