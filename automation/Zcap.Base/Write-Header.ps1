<#
.SYNOPSIS
    Writes a message wrapped with separator lines, or a single separator line.
.PARAMETER Message
    The text to display. If omitted, writes a single separator line.
.PARAMETER Width
    Length of the separator lines. Defaults to 60.
.PARAMETER ForegroundColor
    Color for the output. No color by default (renders as terminal default).
.EXAMPLE
    Write-Header 'Deployment starting'
.EXAMPLE
    Write-Header 'Step 2' -Width 40 -ForegroundColor Cyan
#>
function Write-Header {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $Message,

        [int] $Width = 60,

        [System.ConsoleColor] $ForegroundColor
    )

    $separator = '*' * $Width
    $colorSplat = if ($PSBoundParameters.ContainsKey('ForegroundColor')) { @{ ForegroundColor = $ForegroundColor } } else { @{} }

    if ($Message) {
        Write-InformationColored ("{0}`n* {1}`n{2}" -f $separator, $Message, $separator) @colorSplat
    }
    else {
        Write-InformationColored $separator @colorSplat
    }
}
