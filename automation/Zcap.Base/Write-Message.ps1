<#
.SYNOPSIS
    Writes a status message with calling function name prefix.
.PARAMETER Message
    The message text to write.
.PARAMETER Type
    Output stream: Error, Warning, Host, Verbose, or Debug. Defaults to Host.
.PARAMETER NoNewline
    Suppresses the trailing newline (Host type only).
.PARAMETER NoHeader
    Omits the [timestamp caller] prefix (Host type only).
.PARAMETER ForegroundColor
    Text color (Host type only).
.PARAMETER BackgroundColor
    Background color (Host type only).
.EXAMPLE
    Write-Message 'Deployment complete'
.EXAMPLE
    Write-Message 'Retrying...' -Type Warning
.EXAMPLE
    Write-Message 'Done' -ForegroundColor Green -NoHeader
#>
function Write-Message {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
        [AllowEmptyString()]
        [string] $Message,

        [ValidateSet('Error', 'Warning', 'Host', 'Verbose', 'Debug')]
        [string] $Type = 'Host',

        [switch] $NoNewline,
        [switch] $NoHeader,

        [System.ConsoleColor] $ForegroundColor,
        [System.ConsoleColor] $BackgroundColor
    )

    $callerName = ''
    $callstack = Get-PSCallStack
    if ($callstack.Count -gt 1) {
        $callerName = $callstack[1].Command
        $callerName = if ($callerName -eq '<ScriptBlock>') { ' prompt' } else { " $callerName" }
    }

    $header = if ($env:ZCAP_MESSAGE_TIMESTAMPS) {
        $ts = Get-Date -Format 'HH:mm:ss:fff'
        "[$ts$callerName]"
    } else {
        "[$($callerName.TrimStart())]"
    }

    switch ($Type) {
        'Error' { Write-Error "$header $Message" }
        'Warning' { Write-Warning "$header $Message" }
        'Debug' { Write-Debug "$header $Message" }
        'Verbose' { Write-Verbose "$header $Message" }
        'Host' {
            # Suppress host output during Pester test runs (flag set by Test-Automation)
            if ($global:__PesterRunning) { return }
            if (-not $NoHeader) {
                Write-InformationColored "$header " -NoNewline
            }

            $splat = @{ MessageData = $Message }
            if ($NoNewline) { $splat.NoNewline = $true }
            if ($ForegroundColor) { $splat.ForegroundColor = $ForegroundColor }
            if ($BackgroundColor) { $splat.BackgroundColor = $BackgroundColor }

            Write-InformationColored @splat
        }
    }
}
