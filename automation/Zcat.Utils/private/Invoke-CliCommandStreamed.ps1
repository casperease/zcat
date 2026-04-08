<#
.SYNOPSIS
    Runs a CLI command with live-streamed output, exit code handling, and
    optional structured output capture.
.DESCRIPTION
    Private implementation for Invoke-CliCommand (default mode).

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
.PARAMETER Silent
    Suppress all console output. Output is still captured for -PassThru.
.PARAMETER DryRun
    Return the command string without executing.
#>
function Invoke-CliCommandStreamed {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'By design — executes CLI commands')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification = 'Returns string in -DryRun, Zcat.CliResult in -PassThru')]
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

    # CliRunner is loaded at module import time by _ModuleInit.ps1.
    $runResult = [Zcat.CliRunner]::Run($Command, [bool]$Silent)

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

# --- Module import-time check: detect stale CliRunner type ---
# Runs when this .ps1 file is loaded as a NestedModule, before any function call.
# .NET types survive module reimport — if the .cs file changed, the loaded type is stale.
# Uses a global variable because module scope resets on reimport but .NET types don't.
if (([System.Management.Automation.PSTypeName]'Zcat.CliRunner').Type) {
    $csPath = Join-Path $PSScriptRoot '..' 'assets' 'CliRunner.cs'
    if (Test-Path $csPath) {
        $currentHash = (Get-FileHash $csPath -Algorithm SHA256).Hash
        if ($global:__ZcatCliRunnerHash -and $global:__ZcatCliRunnerHash -ne $currentHash) {
            throw "CliRunner.cs has changed since the Zcat.CliRunner type was loaded. Restart PowerShell to pick up changes."
        }
        $global:__ZcatCliRunnerHash = $currentHash
    }
}
