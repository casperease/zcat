<#
.SYNOPSIS
    Adds a directory to PATH persistently and in the current session.
.DESCRIPTION
    Cross-platform PATH persistence:
    - Windows: writes to the User-scope registry PATH.
    - Linux/macOS: appends a marked block to the PowerShell profile.
    - Always: updates $env:PATH for the current session.

    Idempotent — skips if the path is already present.
.PARAMETER Path
    The directory to add. Must exist.
.PARAMETER Prepend
    Place the path at the beginning instead of the end.
.PARAMETER Label
    Identity marker for Unix profile blocks. Defaults to the leaf folder name.
    Must match when calling Remove-PermanentPath.
.PARAMETER Sync
    After adding, call Sync-SessionPath to merge any other new registry
    entries into the current session (Windows only).
.EXAMPLE
    Add-PermanentPath '/usr/local/go/bin'
.EXAMPLE
    Add-PermanentPath $installDir -Prepend -Label 'Install-Dotnet'
.EXAMPLE
    Add-PermanentPath $toolDir -Sync
#>
function Add-PermanentPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Path,

        [switch] $Prepend,

        [string] $Label,

        [switch] $Sync
    )

    Assert-PathExist $Path -PathType Container

    if (-not $Label) {
        $Label = Split-Path $Path -Leaf
    }

    $separator = [System.IO.Path]::PathSeparator
    $normalizedPath = $Path.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    # --- Session PATH ---
    $entries = $env:PATH -split [regex]::Escape($separator) | Where-Object { $_ -ne '' }
    $comparer = if ($IsWindows) { [System.StringComparer]::OrdinalIgnoreCase } else { [System.StringComparer]::Ordinal }
    $alreadyInSession = $entries | Where-Object {
        $comparer.Equals($_.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar), $normalizedPath)
    } | Select-Object -First 1

    if (-not $alreadyInSession) {
        if ($Prepend) {
            $env:PATH = "$Path$separator$env:PATH"
        }
        else {
            $env:PATH = "$env:PATH$separator$Path"
        }
    }

    # --- Persistent PATH ---
    if ($IsWindows) {
        $userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
        $userEntries = if ($userPath) { $userPath -split ';' | Where-Object { $_ -ne '' } } else { @() }
        $alreadyPersisted = $userEntries | Where-Object {
            $comparer.Equals($_.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar), $normalizedPath)
        } | Select-Object -First 1

        if (-not $alreadyPersisted) {
            if ($Prepend) {
                $userEntries = @($Path) + $userEntries
            }
            else {
                $userEntries = $userEntries + @($Path)
            }
            [System.Environment]::SetEnvironmentVariable('PATH', ($userEntries -join ';'), 'User')
        }
    }
    else {
        $profilePath = $PROFILE.CurrentUserCurrentHost
        $startMarker = ">>> zcap PATH $Label >>>"
        $profileExists = Test-Path $profilePath
        $alreadyPatched = $profileExists -and (Get-Content $profilePath -Raw) -match [regex]::Escape($startMarker)

        if (-not $alreadyPatched) {
            $pathLine = if ($Prepend) {
                "`$env:PATH = `"$Path$separator`$env:PATH`""
            }
            else {
                "`$env:PATH = `"`$env:PATH$separator$Path`""
            }
            $block = @"

# $startMarker
$pathLine
# <<< zcap PATH $Label <<<
"@
            Add-Content -Path $profilePath -Value $block
        }
    }

    if ($Sync) {
        Sync-SessionPath
    }
}
