<#
.SYNOPSIS
    Runs a CLI command with live-streamed output, exit code handling, and
    optional structured output capture.
.DESCRIPTION
    Private implementation for Invoke-Executable (default mode).

    Uses a C# CliRunner class (assets/CliRunner.cs) that reads stdout/stderr
    char-by-char on background threads via Console.Write. Preserves \r
    carriage returns (spinners, progress bars) and Unicode. Output bypasses
    PowerShell's output stream entirely — zero pipeline leaks.

    Limitation: ANSI color codes are NOT preserved. When stdout is redirected
    to a pipe (which Process does internally), most CLI tools detect this via
    isatty() and disable colored output. This is a fundamental OS-level
    constraint — the child process never emits the escape sequences. Solving
    this would require ConPTY (pseudo-terminal). Use -Direct when colors
    are important and pipeline leaks are acceptable.
.PARAMETER Command
    The command string to execute.
.PARAMETER PassThru
    Return a Zcat.CliResult object with Output, Errors, Full, ExitCode, and Raw.
.PARAMETER NoAssert
    Skip the exit code assertion.
.PARAMETER WorkingDirectory
    The directory to run the command in.
.PARAMETER Silent
    Suppress all console output. Output is still captured for -PassThru.
.PARAMETER DryRun
    Return the command string without executing.
#>
function Invoke-ExecutableStreamed {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'By design — executes CLI commands')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification = 'Returns string in -DryRun, Zcat.CliResult in -PassThru')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Command,
        [Parameter(Mandatory)]
        [string] $WorkingDirectory,
        [switch] $PassThru,
        [switch] $NoAssert,
        [switch] $Silent,
        [switch] $DryRun
    )

    if ($DryRun) {
        return $Command
    }

    Reset-LastExitCode

    # CliRunner is loaded at module import time by _ModuleInit.ps1.
    $runResult = [Zcat.CliRunner]::Run($Command, [bool]$Silent, $WorkingDirectory)

    # Set $LASTEXITCODE so Assert-LastExitCodeWasZero works
    $global:LASTEXITCODE = $runResult.ExitCode

    if (-not $NoAssert) {
        Assert-LastExitCodeWasZero
    }

    Reset-LastExitCode

    if ($PassThru) {
        $stdText = $runResult.Stdout.TrimEnd("`r", "`n")
        $errText = $runResult.Stderr.TrimEnd("`r", "`n")
        $fullText = @($stdText, $errText | Where-Object { $_ }) -join [Environment]::NewLine

        [PSCustomObject]@{
            PSTypeName = 'Zcat.CliResult'
            Output     = $stdText
            Errors     = $errText
            Full       = $fullText
            ExitCode   = $runResult.ExitCode
            Raw        = @($stdText -split [Environment]::NewLine)
        }
    }
}
