<#
.SYNOPSIS
    Runs dotnet with the given arguments.
.DESCRIPTION
    Asserts that the installed .NET SDK version matches the locked version
    in Get-ToolConfig before executing the command.
.PARAMETER Arguments
    Arguments to pass to dotnet.
.PARAMETER PassThru
    Return a Zcat.CliResult object with Output, Errors, Full, and ExitCode.
.PARAMETER NoAssert
    Skip exit code assertion.
.PARAMETER Silent
    Suppress the command log line.
.PARAMETER DryRun
    Return the command string without executing. Used for testing.
.EXAMPLE
    Invoke-Dotnet 'build'
.EXAMPLE
    Invoke-Dotnet '--version' -DryRun
#>
function Invoke-Dotnet {
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
        Assert-Tool 'Dotnet'
    }

    Invoke-CliCommand "dotnet $Arguments" -PassThru:$PassThru -NoAssert:$NoAssert -Silent:$Silent -DryRun:$DryRun
}
