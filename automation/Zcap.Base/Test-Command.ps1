<#
.SYNOPSIS
    Tests whether a command exists in the current session.
.DESCRIPTION
    Returns $false for Windows Store app execution alias stubs
    (e.g., python.exe in WindowsApps) — these are not real installations.
.PARAMETER Command
    The command name to check.
.EXAMPLE
    Test-Command 'git'
#>
function Test-Command {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Command
    )

    $cmd = Get-Command $Command -ErrorAction Ignore
    if (-not $cmd) { return $false }

    # Windows Store app execution aliases include zero-byte stubs that redirect to
    # the Microsoft Store. They pass Get-Command but are not real installations.
    # Real Store apps (e.g., winget.exe) also live here and must not be filtered.
    if ($IsWindows -and $cmd.Source -match 'Microsoft\\WindowsApps') {
        $file = Get-Item $cmd.Source -ErrorAction Ignore
        if ($file -and $file.Length -eq 0) {
            Write-Verbose "Ignoring Windows Store stub: $($cmd.Source)"
            return $false
        }
    }

    $true
}
