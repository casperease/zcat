<#
.SYNOPSIS
    Writes a message wrapped with separator lines, or a single separator line.
.PARAMETER Message
    The text to display. If omitted, writes a single separator line.
.PARAMETER Width
    Length of the separator lines. Defaults to 60.
.PARAMETER ForegroundColor
    Color for the output. Defaults to Blue.
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

        [System.ConsoleColor] $ForegroundColor = 'Blue'
    )

    $separator = '*' * $Width

    if ($Message) {
        Write-InformationColored ("{0}`n* {1}`n{2}" -f $separator, $Message, $separator) -ForegroundColor $ForegroundColor
    }
    else {
        Write-InformationColored $separator -ForegroundColor $ForegroundColor
    }
}
