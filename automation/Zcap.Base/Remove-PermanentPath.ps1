<#
.SYNOPSIS
    Removes a directory from PATH persistently and in the current session.
.DESCRIPTION
    Cross-platform PATH removal:
    - Windows: removes from the User-scope registry PATH.
    - Linux/macOS: removes the marked block from the PowerShell profile.
    - Always: removes from $env:PATH for the current session.

    Idempotent — no error if the path is not present.
.PARAMETER Path
    The directory to remove.
.PARAMETER Label
    Identity marker for Unix profile blocks. Must match the label used
    when Add-PermanentPath was called. Defaults to the leaf folder name.
.PARAMETER Sync
    After removing, call Sync-SessionPath to refresh the session PATH
    from the registry (Windows only).
.EXAMPLE
    Remove-PermanentPath '/usr/local/go/bin'
.EXAMPLE
    Remove-PermanentPath $installDir -Label 'Install-Dotnet'
#>
function Remove-PermanentPath {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Path,

        [string] $Label,

        [switch] $Sync
    )

    if (-not $Label) {
        $Label = Split-Path $Path -Leaf
    }

    $separator = [System.IO.Path]::PathSeparator
    $normalizedPath = $Path.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    # --- Session PATH ---
    $comparer = if ($IsWindows) { [System.StringComparer]::OrdinalIgnoreCase } else { [System.StringComparer]::Ordinal }
    $env:PATH = ($env:PATH -split [regex]::Escape($separator) |
        Where-Object {
            $_ -ne '' -and -not $comparer.Equals(
                $_.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar),
                $normalizedPath)
        }) -join $separator

    # --- Persistent PATH ---
    if ($IsWindows) {
        $userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
        if ($userPath) {
            $cleaned = ($userPath -split ';' |
                Where-Object {
                    $_ -ne '' -and -not $comparer.Equals(
                        $_.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar),
                        $normalizedPath)
                }) -join ';'
            [System.Environment]::SetEnvironmentVariable('PATH', $cleaned, 'User')
        }
    }
    else {
        $profilePath = $PROFILE.CurrentUserCurrentHost
        if (Test-Path $profilePath) {
            $content = Get-Content $profilePath -Raw
            $startMarker = ">>> zcap PATH $Label >>>"
            $endMarker = "<<< zcap PATH $Label <<<"
            $cleaned = $content -replace "(?s)\r?\n?# $([regex]::Escape($startMarker)).*?# $([regex]::Escape($endMarker))\r?\n?", ''
            if ($cleaned -ne $content) {
                Set-Content -Path $profilePath -Value $cleaned -NoNewline
            }
        }
    }

    if ($Sync) {
        Sync-SessionPath
    }
}
