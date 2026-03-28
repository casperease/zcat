<#
.SYNOPSIS
    Runs az with the given arguments.
.DESCRIPTION
    Asserts that the installed Azure CLI version matches the locked version
    in Get-ToolConfig before executing the command.
.PARAMETER Arguments
    Arguments to pass to az.
.PARAMETER PassThru
    Capture and return the output.
.PARAMETER NoAssert
    Skip exit code assertion.
.PARAMETER Silent
    Suppress the command log line.
.PARAMETER DryRun
    Return the command string without executing. Used for testing.
.EXAMPLE
    Invoke-AzCli 'account show'
.EXAMPLE
    Invoke-AzCli 'group list' -PassThru
.EXAMPLE
    Invoke-AzCli 'version' -DryRun
#>
function Invoke-AzCli {
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
        Assert-Tool 'AzCli'
    }

    Invoke-CliCommand "az $Arguments" -PassThru:$PassThru -NoAssert:$NoAssert -Silent:$Silent -DryRun:$DryRun
}
