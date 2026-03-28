<#
.SYNOPSIS
    Tests whether a command exists in the current session.
.DESCRIPTION
    Returns $true if the command is found via Get-Command and is a real
    executable. Returns $false for Windows Store app execution alias stubs
    (reparse points in WindowsApps that redirect to the Store).
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

    # Windows Store app execution alias stubs are reparse points with zero
    # length inside WindowsApps. Detect via both attributes: the file must
    # be a ReparsePoint AND 0 bytes (real executables installed via winget
    # into WindowsApps are not reparse points).
    if ($IsWindows -and $cmd.Source) {
        $file = Get-Item $cmd.Source -Force -ErrorAction Ignore
        if ($file -and $file.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint) -and $file.Length -eq 0) {
            return $false
        }
    }

    $true
}
