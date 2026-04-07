<#
.SYNOPSIS
    Runs terraform with the given arguments.
.DESCRIPTION
    Asserts that the installed Terraform version matches the locked version
    in Get-ToolConfig before executing the command.
.PARAMETER Arguments
    Arguments to pass to terraform.
.PARAMETER PassThru
    Return a Zcat.CliResult object with Output, Errors, Full, and ExitCode.
.PARAMETER NoAssert
    Skip exit code assertion.
.PARAMETER Silent
    Suppress the command log line.
.PARAMETER DryRun
    Return the command string without executing. Used for testing.
.EXAMPLE
    Invoke-Terraform 'plan'
.EXAMPLE
    Invoke-Terraform 'plan' -DryRun
#>
function Invoke-Terraform {
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
        Assert-Tool 'Terraform'
    }

    Invoke-CliCommand "terraform $Arguments" -PassThru:$PassThru -NoAssert:$NoAssert -Silent:$Silent -DryRun:$DryRun
}
