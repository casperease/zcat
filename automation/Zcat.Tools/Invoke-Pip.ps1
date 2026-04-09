<#
.SYNOPSIS
    Runs pip with the given arguments.
.DESCRIPTION
    Asserts Python is available before executing.
    Uses python -m pip to ensure the correct pip is used.
    For install commands, asserts version match and checks scope.
.PARAMETER Arguments
    Arguments to pass to pip.
.PARAMETER PassThru
    Return a Zcat.CliResult object with Output, Errors, Full, and ExitCode.
.PARAMETER NoAssert
    Skip exit code assertion.
.PARAMETER Silent
    Suppress the command log line and all console output.
.PARAMETER DryRun
    Return the command string without executing. Used for testing.
.EXAMPLE
    Invoke-Pip 'install requests'
.EXAMPLE
    Invoke-Pip 'install requests' -DryRun
#>
function Invoke-Pip {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Arguments,
        [switch] $PassThru,
        [switch] $NoAssert,
        [switch] $Silent,
        [switch] $DryRun
    )

    Assert-NotNullOrWhitespace $Arguments -ErrorText 'Arguments cannot be empty'

    if (-not $DryRun) {
        Assert-Tool 'Python'
    }

    Invoke-Executable "python -m pip $Arguments" -PassThru:$PassThru -NoAssert:$NoAssert -Silent:$Silent -DryRun:$DryRun
}
