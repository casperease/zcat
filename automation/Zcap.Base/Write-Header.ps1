<#
.SYNOPSIS
    Writes a header with optional message using box-drawing characters.
.DESCRIPTION
    Renders a top-style box section:
      ╭────────────────────╮
      │ Message             │
      ╭────────────────────╮
    Without a message, renders a single top line:
      ╭────────────────────╮
.PARAMETER Message
    The text to display. If omitted, writes a single top line.
.PARAMETER Width
    Total width of the box lines. Defaults to 60.
.PARAMETER ForegroundColor
    Color for the output. No color by default (renders as terminal default).
.EXAMPLE
    Write-Header 'Deployment starting'
.EXAMPLE
    Write-Header -ForegroundColor Cyan
#>
function Write-Header {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $Message,

        [int] $Width = 60,

        [System.ConsoleColor] $ForegroundColor
    )

    $colorSplat = if ($PSBoundParameters.ContainsKey('ForegroundColor')) { @{ ForegroundColor = $ForegroundColor } } else { @{} }

    $inner = $Width - 2
    $topLine = "╭$('─' * $inner)╮"
    $bottomLine = "╰$('─' * $inner)╯"

    if ($Message) {
        $maxMsg = $inner - 2
        $msgLine = if ($Message.Length -le $maxMsg) {
            "│ $($Message.PadRight($maxMsg)) │"
        }
        else {
            "│ $Message"
        }
        Write-InformationColored "$topLine`n$msgLine`n$bottomLine" @colorSplat
    }
    else {
        Write-InformationColored $topLine @colorSplat
    }
}
