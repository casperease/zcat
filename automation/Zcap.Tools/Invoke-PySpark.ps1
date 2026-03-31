<#
.SYNOPSIS
    Runs pyspark with the given arguments.
.DESCRIPTION
    Asserts that the installed PySpark version matches the locked version
    in Get-ToolConfig before executing the command. Also asserts Java
    is available (DependsOn in tools.yml).
.PARAMETER Arguments
    Arguments to pass to pyspark.
.PARAMETER PassThru
    Return a Zcap.CliResult object with Output, Errors, Full, and ExitCode.
.PARAMETER NoAssert
    Skip exit code assertion.
.PARAMETER Silent
    Suppress the command log line.
.PARAMETER DryRun
    Return the command string without executing. Used for testing.
.EXAMPLE
    Invoke-PySpark '--version'
.EXAMPLE
    Invoke-PySpark '--version' -DryRun
#>
function Invoke-PySpark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Arguments,
        [switch] $PassThru,
        [switch] $NoAssert,
        [switch] $Silent,
        [switch] $DryRun
    )

    if (-not $DryRun) {
        Assert-Tool 'PySpark'
    }

    Invoke-CliCommand "pyspark $Arguments" -PassThru:$PassThru -NoAssert:$NoAssert -Silent:$Silent -DryRun:$DryRun
}
