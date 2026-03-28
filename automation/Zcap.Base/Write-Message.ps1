<#
.SYNOPSIS
    Writes a status message with calling function name prefix.
.DESCRIPTION
    Writes to the information stream via Write-InformationColored.
    Automatically prepends the calling function name as a header.
    Suppressed during Pester test runs to keep test output clean.
.PARAMETER Message
    The message text to write.
.PARAMETER NoHeader
    Omits the [caller] prefix.
.PARAMETER NoNewline
    Suppresses the trailing newline.
.PARAMETER ForegroundColor
    Text color.
.PARAMETER BackgroundColor
    Background color.
.EXAMPLE
    Write-Message 'Deployment complete'
.EXAMPLE
    Write-Message 'Done' -ForegroundColor Green -NoHeader
#>
function Write-Message {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
        [AllowEmptyString()]
        [string] $Message,

        [switch] $NoHeader,
        [switch] $NoNewline,

        [System.ConsoleColor] $ForegroundColor,
        [System.ConsoleColor] $BackgroundColor
    )

    # Suppress during Pester test runs (flag set by Test-Automation)
    if ($global:__PesterRunning) { return }

    if (-not $NoHeader) {
        $callerName = ''
        $callstack = Get-PSCallStack
        if ($callstack.Count -gt 1) {
            $callerName = $callstack[1].Command
            $callerName = if ($callerName -eq '<ScriptBlock>') { 'prompt' } else { $callerName }
        }

        $header = if ($env:ZCAP_MESSAGE_TIMESTAMPS) {
            $ts = Get-Date -Format 'HH:mm:ss.fff'
            "[$ts $callerName]"
        } else {
            "[$callerName]"
        }

        Write-InformationColored "$header " -NoNewline
    }

    $splat = @{ MessageData = $Message }
    if ($NoNewline) { $splat.NoNewline = $true }
    if ($ForegroundColor) { $splat.ForegroundColor = $ForegroundColor }
    if ($BackgroundColor) { $splat.BackgroundColor = $BackgroundColor }

    Write-InformationColored @splat
}
