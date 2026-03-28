<#
.SYNOPSIS
    Runs a CLI command with exit code handling and optional output capture.
.DESCRIPTION
    Resets LASTEXITCODE, runs the command, and asserts exit code is zero.
    Optionally captures and returns output via -PassThru.
    Use -DryRun to return the command string without executing.
.PARAMETER Command
    The command string to execute.
.PARAMETER PassThru
    Capture and return the command output.
.PARAMETER NoAssert
    Skip the exit code assertion.
.PARAMETER Silent
    Suppress the command log line. Used for internal plumbing calls.
.PARAMETER DryRun
    Return the command string without executing. Used for testing.
.EXAMPLE
    Invoke-CliCommand 'python --version'
.EXAMPLE
    $output = Invoke-CliCommand 'python --version' -PassThru
.EXAMPLE
    Invoke-CliCommand 'python --version' -DryRun
#>
# Note: uses -DryRun instead of ShouldProcess/-WhatIf because ShouldProcess
# writes to the host (not capturable) and we need the command string returned
# via Write-Output for testability. -Confirm is not needed for CLI commands.
function Invoke-CliCommand {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'By design — executes CLI commands')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification = 'Returns string only in -DryRun mode')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Command,
        [switch] $PassThru,
        [switch] $NoAssert,
        [switch] $Silent,
        [switch] $DryRun
    )

    if ($DryRun) {
        return $Command
    }

    Reset-LastExitCode

    if (-not $Silent) {
        Write-Message $Command
    }

    if ($PassThru) {
        $result = Invoke-Expression $Command
    }
    else {
        Invoke-Expression $Command
    }

    if (-not $NoAssert) {
        Assert-LastExitCodeWasZero
    }

    Reset-LastExitCode

    if ($PassThru) {
        $result
    }
}
