<#
.SYNOPSIS
    Rebuilds the session PATH from the registry on Windows. No-op on Unix.
.DESCRIPTION
    Reads Machine and User PATH from the Windows registry and rebuilds
    $env:PATH. Registry entries form the base; session-only entries
    (e.g. from Add-PermanentPath or a tool's install script) are kept
    only if their directory still exists on disk.

    This handles both directions:
    - New entries added to the registry by an installer appear in the session.
    - Entries removed from the registry by an uninstaller disappear from
      the session (even if the directory still exists on disk).

    On Linux/macOS this function is a no-op — package managers update PATH
    through profile scripts that take effect on next shell launch.
.EXAMPLE
    Sync-SessionPath
#>
function Sync-SessionPath {
    [CmdletBinding()]
    param()

    if (-not $IsWindows) { return }

    $machinePath = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    $registryPaths = ($userPath, $machinePath | ForEach-Object { $_ -split ';' }) |
        Where-Object { $_ -ne '' }

    # Build the set of all registry entries (normalized for dedup)
    $registrySet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($p in $registryPaths) {
        $registrySet.Add($p.TrimEnd('\', '/')) | Out-Null
    }

    # Keep session-only entries only if they still exist on disk
    $currentPaths = $env:PATH -split ';' | Where-Object { $_ -ne '' }
    $kept = foreach ($p in $currentPaths) {
        $normalized = $p.TrimEnd('\', '/')
        if ($registrySet.Contains($normalized)) { $p }
        elseif (Test-Path $p) { $p }
    }

    # Add any registry entries not yet in the session
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]($kept | ForEach-Object { $_.TrimEnd('\', '/') }),
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $newPaths = foreach ($p in $registryPaths) {
        if ($seen.Add($p.TrimEnd('\', '/'))) { $p }
    }

    $env:PATH = (@($kept) + @($newPaths)) -join ';'
}
