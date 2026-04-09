<#
.SYNOPSIS
    Runs a CLI command with exit code handling, stream separation, and
    optional structured output capture.
.DESCRIPTION
    Central wrapper for external tool invocation.

    Default: Live-streams output to the console via a C# process runner
    that reads char-by-char (preserves spinners, progress bars, \r).
    Output bypasses PowerShell's pipeline — zero leaks. With -PassThru,
    returns a Zcat.CliResult object with separated stdout/stderr.
    Note: ANSI colors are lost — child processes disable them when stdout
    is a pipe (isatty check). Use -Direct when colors matter.

    -Direct: Like typing the command at the prompt. Full color, full
    fidelity. Output flows to the console AND the pipeline — leaks into
    caller's return value. Use for interactive commands or when colors
    are important.

    Both modes share the same LASTEXITCODE lifecycle (reset before, assert
    after, reset after). -PassThru returns a Zcat.CliResult object:
      .Output   — stdout only (string)
      .Errors   — stderr only (string)
      .Full     — both merged in original order (string)
      .ExitCode — raw exit code (int)
      .Raw      — unprocessed output array

    -PassThru and -Direct are mutually exclusive (separate parameter sets).
.PARAMETER Command
    The command string to execute.
.PARAMETER Direct
    Raw execution with full color support. Output leaks to the pipeline.
    Use when colors matter or for interactive commands.
.PARAMETER PassThru
    Return a Zcat.CliResult object with Output, Errors, Full, ExitCode, and Raw.
    Not compatible with -Direct.
.PARAMETER NoAssert
    Skip the exit code assertion. The ExitCode is still available on the
    result object when combined with -PassThru.
.PARAMETER Silent
    Suppress the command log line and all console output.
.PARAMETER WorkingDirectory
    The directory to run the command in. Defaults to the repository root
    ($env:RepositoryRoot). Callers that need a specific directory should
    pass it explicitly rather than relying on $PWD.
.PARAMETER DryRun
    Return the command string without executing. Used for testing.
.EXAMPLE
    Invoke-Executable 'python --version'
.EXAMPLE
    Invoke-Executable 'winget install --id Python.Python.3.11' -Direct
.EXAMPLE
    $result = Invoke-Executable 'az account show --output json' -PassThru
    $result.Output | ConvertFrom-Json
.EXAMPLE
    $result = Invoke-Executable 'terraform apply' -PassThru
    $result.ExitCode
.EXAMPLE
    Invoke-Executable 'python --version' -DryRun
#>
# Note: uses -DryRun instead of ShouldProcess/-WhatIf because ShouldProcess
# writes to the host (not capturable) and we need the command string returned
# via Write-Output for testability. -Confirm is not needed for CLI commands.
function Invoke-Executable {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'By design — executes CLI commands via private helpers')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification = 'Returns string in -DryRun, Zcat.CliResult in -PassThru')]
    [CmdletBinding(DefaultParameterSetName = 'Stream')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Command,

        [Parameter(ParameterSetName = 'Direct')]
        [switch] $Direct,

        [Parameter(ParameterSetName = 'Stream')]
        [switch] $PassThru,

        [switch] $NoAssert,
        [switch] $Silent,
        [string] $WorkingDirectory = (Get-RepositoryRoot),
        [switch] $DryRun
    )

    Assert-PathExist $WorkingDirectory -PathType Container

    # Log the command from this function so Write-Message shows [Invoke-Executable].
    if (-not $Silent -and -not $DryRun) {
        Write-Message $Command
    }

    $params = @{
        Command          = $Command
        WorkingDirectory = $WorkingDirectory
        PassThru         = $PassThru
        NoAssert         = $NoAssert
        Silent           = $Silent
        DryRun           = $DryRun
    }

    if ($Direct) {
        Invoke-ExecutableDirect @params
    }
    else {
        Invoke-ExecutableStreamed @params
    }
}
