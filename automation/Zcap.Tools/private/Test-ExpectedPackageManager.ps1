<#
.SYNOPSIS
    Tests whether a tool is managed by the expected package manager.
.DESCRIPTION
    Checks the platform's expected package manager to determine if it
    currently manages the given tool. Check order: UserInstallDir (script-
    installed), platform-specific (winget/brew/apt), then pip (cross-
    platform fallback). Returns $false if the manager is not available.
.PARAMETER Config
    Tool configuration hashtable from Get-ToolConfig / tools.yml.
#>
function Test-ExpectedPackageManager {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config,

        # Pre-fetched winget list output. When provided, skips the per-tool
        # winget list call — pass the result of Get-WingetListCache.
        [string] $WingetListCache
    )

    # 1. Script-installed tools (e.g., Dotnet via dotnet-install scripts).
    if ($Config.ScriptInstall) {
        if (-not (Test-Command $Config.Command)) { return $false }
        $location = (Get-Command $Config.Command).Source
        $expectedDir = Get-ScriptInstallDir -Config $Config
        return $location -like "$expectedDir*"
    }

    # 2. Platform-specific package managers — only if the tool has the field
    #    for the current platform.
    if ($IsWindows -and $Config.WingetId) {
        if (-not (Test-Command winget)) { return $false }

        # Build a search prefix that matches any version of this tool.
        # Format-string IDs like "Python.Python.{0}" become "Python.Python".
        $baseId = ($Config.WingetId -replace '\{0\}', '').TrimEnd('.', '-')

        # For IDs without a format placeholder the version may be hardcoded
        # as the last segment (e.g., Microsoft.DotNet.SDK.10). Strip it so
        # the search finds any installed version, not just the locked one.
        if ($Config.WingetId -notmatch '\{0\}') {
            $parts = $baseId -split '\.'
            if ($parts.Count -gt 2 -and $parts[-1] -match '^\d') {
                $baseId = $parts[0..($parts.Count - 2)] -join '.'
            }
        }

        # Use pre-fetched cache when available (single winget list call for all tools).
        if ($WingetListCache) {
            return $WingetListCache -match [regex]::Escape($baseId)
        }

        try {
            $output = (& winget list --id $baseId --accept-source-agreements --disable-interactivity 2>$null) -join "`n"
        }
        catch {
            return $false
        }
        return $output -match [regex]::Escape($baseId)
    }

    if ($IsMacOS -and $Config.BrewFormula) {
        if (-not (Test-Command brew)) { return $false }
        $formula = ($Config.BrewFormula -replace '\{0\}', '').TrimEnd('@', '-')
        try {
            & brew list $formula 2>$null | Out-Null
        }
        catch {
            return $false
        }
        return $LASTEXITCODE -eq 0
    }

    if ($IsLinux -and $Config.AptPackage) {
        if (-not (Test-Command dpkg)) { return $false }
        $package = ($Config.AptPackage -replace '\{0\}', '').TrimEnd('-')
        try {
            & dpkg -s $package 2>$null | Out-Null
        }
        catch {
            return $false
        }
        return $LASTEXITCODE -eq 0
    }

    # 3. pip — cross-platform fallback. Catches Poetry everywhere and AzCli
    #    on Windows/Linux. On macOS, AzCli already matched brew above.
    if ($Config.PipPackage) {
        if (-not (Test-Command pip)) { return $false }
        try {
            $output = & pip show $Config.PipPackage 2>$null
        }
        catch {
            return $false
        }
        return [bool]$output
    }

    $false
}
