<#
.SYNOPSIS
    Displays exception details for use in catch blocks.
.DESCRIPTION
    Prints exception type, message, script stack trace, and any inner exceptions.
    Falls back to $global:Error if no ErrorRecord is provided.
.PARAMETER ErrorRecord
    The ErrorRecord to display. If omitted, uses $global:Error.
.PARAMETER GlobalErrorIndex
    Index into $global:Error when no ErrorRecord is given. Defaults to 0 (most recent).
.EXAMPLE
    try { Get-Item C:\no } catch { Write-Exception $_ }
.EXAMPLE
    Write-Exception -GlobalErrorIndex 2
#>
function Write-Exception {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ParameterSetName = 'FromParameter')]
        [System.Management.Automation.ErrorRecord] $ErrorRecord,

        [Parameter(Position = 0, ParameterSetName = 'FromGlobal')]
        [int] $GlobalErrorIndex = 0
    )

    if (-not $ErrorRecord) {
        $ErrorRecord = $global:Error[$GlobalErrorIndex]
    }

    if (-not $ErrorRecord) {
        Write-Verbose 'No error to display'
        return
    }

    $traceLines = $ErrorRecord.ScriptStackTrace -split "`n"
    $trace = $traceLines | ForEach-Object {
        if ($_ -match 'at <ScriptBlock>, <No file>: line \d+') {
            $lastCmd = (Get-History -Count 1).CommandLine
            if ($lastCmd) {
                $lastCmd = ($lastCmd -replace '[\r\n]+', ' ').Trim()
                if ($lastCmd.Length -gt 30) { $lastCmd = $lastCmd.Substring(0, 30) + '...' }
                "at $lastCmd"
            } else { 'at <prompt>' }
        }
        else { $_ }
    }

    $lines = @(
        $ErrorRecord.Exception.GetType().FullName
        $ErrorRecord.Exception.Message
        $trace
    )

    $inner = $ErrorRecord.Exception.InnerException
    for ($i = 1; $inner; $i++, ($inner = $inner.InnerException)) {
        $lines += "--- Inner exception ($i): $($inner.GetType().FullName) ---"
        $lines += $inner.Message
    }

    $inPipeline = Test-IsRunningInPipeline

    foreach ($line in $lines) {
        if ($inPipeline) {
            Write-Information "##[error]$line"
        }
        else {
            Write-InformationColored $line -ForegroundColor Red
        }
    }
}
