<#
.SYNOPSIS
    Tests whether a tool is managed by the expected package manager.
.DESCRIPTION
    Checks the platform's expected package manager (winget on Windows,
    brew on macOS, apt on Linux, pip for pip-based tools) to determine
    if it currently manages the given tool. Returns $false if the
    manager itself is not available.
.PARAMETER Config
    Tool configuration hashtable from Get-ToolConfig / tools.yml.
#>
function Test-ExpectedPackageManager {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    # pip-managed tools (e.g., Poetry)
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

    if ($IsWindows) {
        if (-not $Config.WingetId -or -not (Test-Command winget)) { return $false }

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

        try {
            $output = (& winget list --id $baseId --accept-source-agreements --disable-interactivity 2>$null) -join "`n"
        }
        catch {
            return $false
        }
        return $output -match [regex]::Escape($baseId)
    }

    if ($IsMacOS) {
        if (-not $Config.BrewFormula -or -not (Test-Command brew)) { return $false }
        $formula = ($Config.BrewFormula -replace '\{0\}', '').TrimEnd('@', '-')
        try {
            & brew list $formula 2>$null | Out-Null
        }
        catch {
            return $false
        }
        return $LASTEXITCODE -eq 0
    }

    if ($IsLinux) {
        if (-not $Config.AptPackage -or -not (Test-Command dpkg)) { return $false }
        $package = ($Config.AptPackage -replace '\{0\}', '').TrimEnd('-')
        try {
            & dpkg -s $package 2>$null | Out-Null
        }
        catch {
            return $false
        }
        return $LASTEXITCODE -eq 0
    }

    $false
}
