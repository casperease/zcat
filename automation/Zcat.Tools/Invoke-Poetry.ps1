<#
.SYNOPSIS
    Runs poetry with the given arguments.
.DESCRIPTION
    Asserts that the installed Poetry version matches the locked version
    in Get-ToolConfig before executing the command.
.PARAMETER Arguments
    Arguments to pass to poetry.
.PARAMETER PassThru
    Return a Zcat.CliResult object with Output, Errors, Full, and ExitCode.
.PARAMETER NoAssert
    Skip exit code assertion.
.PARAMETER Silent
    Suppress the command log line.
.EXAMPLE
    Invoke-Poetry 'install'
.EXAMPLE
    Invoke-Poetry 'version' -PassThru
#>
function Invoke-Poetry {
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
        Assert-Tool 'Poetry'
    }

    Invoke-CliCommand "poetry $Arguments" -PassThru:$PassThru -NoAssert:$NoAssert -Silent:$Silent -DryRun:$DryRun
}
