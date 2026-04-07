<#
.SYNOPSIS
    Provisions the local development environment with all required tools.
.DESCRIPTION
    Installs all locked tool versions in dependency order (derived from
    DependsOn in tools.yml). Idempotent — safe to run repeatedly. Skips
    tools that are already installed at the correct version. Tools at the
    correct version but installed outside the expected manager are left
    untouched with a message.
.PARAMETER Force
    Replace existing installations that are at the wrong version.
.EXAMPLE
    Install-DevBoxTools
.EXAMPLE
    Install-DevBoxTools -Force
#>
function Install-DevBoxTools {
    [CmdletBinding()]
    param(
        [switch] $Force
    )

    # Remove Chocolatey if present — this toolset uses winget on Windows.
    # See ADR: use-proper-package-managers.
    Uninstall-Chocolatey

    # Report tools that work but aren't managed by us — left untouched.
    $status = Get-ToolsStatus
    $usable = @($status | Where-Object { $_.Status -eq 'Usable' })
    foreach ($tool in $usable) {
        Write-Message "Skipping $($tool.Tool) — $($tool.Installed) already installed, not managed by tools system"
    }

    # Version-locked tools (from tools.yml, dependency-ordered via DependsOn)
    foreach ($toolName in Get-ToolInstallOrder) {
        $installCmd = "Install-$toolName"
        if (-not (Get-Command $installCmd -ErrorAction SilentlyContinue)) {
            throw "No $installCmd function found for tool '$toolName' defined in tools.yml"
        }

        $config = Get-ToolConfig -Tool $toolName
        if ($config.PipPackage -and -not $config.ScriptInstall) {
            # Pip tools don't support -Force (version is pinned by pip ==version.*)
            & $installCmd
        }
        else {
            & $installCmd -Force:$Force
        }
    }

    # Additional tools (not version-locked, not in tools.yml)
    Install-Git -Force:$Force
    Install-Postman -Force:$Force
}
