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

    # Windows Store app execution aliases are zero-byte stubs that redirect to
    # the Microsoft Store. They pass Get-Command but are not real installations.
    if ($IsWindows -and $cmd.Source -match 'Microsoft\\WindowsApps') {
        Write-Verbose "Ignoring Windows Store stub: $($cmd.Source)"
        return $false
    }

    $true
}
