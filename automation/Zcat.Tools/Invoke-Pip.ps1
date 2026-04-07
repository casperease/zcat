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
        [switch] $DryRun
    )

    Assert-NotNullOrWhitespace $Arguments -ErrorText 'Arguments cannot be empty'

    if (-not $DryRun) {
        Assert-Tool 'Python'
    }

    Invoke-CliCommand "python -m pip $Arguments" -PassThru:$PassThru -NoAssert:$NoAssert -DryRun:$DryRun
}
