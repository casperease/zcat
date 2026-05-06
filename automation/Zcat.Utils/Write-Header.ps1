<#
.SYNOPSIS
    Writes a header with optional message in a chosen style.
.DESCRIPTION
    Styles (with message / without message):

      Curved (default):
        ╭──────────────╮       ╭──────────────╮
        │ Message      │
        ╰──────────────╯

      Stars:
        ****************       ****************
        * Message
        ****************

.PARAMETER Message
    The text to display. If omitted, writes a single separator line.
.PARAMETER Style
    Visual style: Curved, Stars, or Line. Defaults to Curved.
.PARAMETER Width
    Total width of the separator lines. Defaults to 60.
.PARAMETER ForegroundColor
    Color for the output. No color by default (renders as terminal default).
.EXAMPLE
    Write-Header 'Deployment starting'
.EXAMPLE
    Write-Header 'Build' -Style Stars -ForegroundColor Yellow
.EXAMPLE
    Write-Header -Style Line
#>
function Write-Header {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $Message,

        [ValidateSet('Curved', 'Stars', 'Heavy')]
        [string] $Style = 'Curved',

        [int] $Width = 78,

        [System.ConsoleColor] $ForegroundColor
    )

    $colorSplat = if ($PSBoundParameters.ContainsKey('ForegroundColor')) { @{ ForegroundColor = $ForegroundColor } } else { @{} }

    switch ($Style) {
        'Curved' {
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
                Write-InformationColored "$topLine`n" @colorSplat
            }
        }
        'Stars' {
            $separator = '*' * $Width
            $maxMsg = $Width - 4  # "* " + message + " *"

            if ($Message) {
                $msgLine = if ($Message.Length -le $maxMsg) {
                    "* $($Message.PadRight($maxMsg)) *"
                }
                else {
                    "* $Message"
                }
                Write-InformationColored "$separator`n$msgLine`n$separator" @colorSplat
            }
            else {
                Write-InformationColored $separator @colorSplat
            }
        }
        'Heavy' {
            $inner = $Width - 2
            $topLine = "╔$('═' * $inner)╗"
            $bottomLine = "╚$('═' * $inner)╝"
            $maxMsg = $inner - 2

            if ($Message) {
                $msgLine = if ($Message.Length -le $maxMsg) {
                    "║ $($Message.PadRight($maxMsg)) ║"
                }
                else {
                    "║ $Message"
                }
                Write-InformationColored "$topLine`n$msgLine`n$bottomLine" @colorSplat
            }
            else {
                Write-InformationColored $topLine @colorSplat
            }
        }
    }
}
