<#
.SYNOPSIS
    Runs a CLI command directly with no output capture or stream separation.
.DESCRIPTION
    Private implementation for Invoke-CliCommand -Direct.

    Output flows straight to the console as if the command were typed
    at the prompt. No buffering, no capture, no stream separation.
    Just the LASTEXITCODE lifecycle (reset, execute, assert, reset).

    -PassThru is accepted but ignored — there is nothing to return.
    Use the default (Stream) mode when you need structured output.
.PARAMETER Command
    The command string to execute.
.PARAMETER PassThru
    Accepted for signature compatibility. Ignored — Direct mode does not
    capture output.
.PARAMETER NoAssert
    Skip the exit code assertion.
.PARAMETER Silent
    Suppress the command log line.
.PARAMETER DryRun
    Return the command string without executing.
#>
function Invoke-CliCommandDirect {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'By design — executes CLI commands')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'PassThru', Justification = 'Accepted for signature compatibility with other modes')]
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

    # Run directly — output flows straight to the console handle.
    # No pipes, no interception. Spinners, progress bars, \r overwrites all work.
    # Output WILL leak to the pipeline — callers must suppress if needed.
    # Child scope prevents $ErrorActionPreference = 'Continue' from leaking.
    & {
        $ErrorActionPreference = 'Continue'
        Invoke-Expression $Command
    }

    if (-not $NoAssert) {
        Assert-LastExitCodeWasZero
    }

    Reset-LastExitCode
}
