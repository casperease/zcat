<#
.SYNOPSIS
    Writes the current call stack in red for debugging.
.EXAMPLE
    Write-CallStack
#>
function Write-CallStack {
    [CmdletBinding()]
    param()

    $callstack = Get-PSCallStack

    if ($callstack.Count -eq 0) {
        Write-Information 'Unknown caller'
        return
    }

    $output = $callstack | ForEach-Object {
        '{0}:{1}' -f $_.ScriptName, $_.ScriptLineNumber
    }

    Write-InformationColored ($output -join "`n") -ForegroundColor Red
}
