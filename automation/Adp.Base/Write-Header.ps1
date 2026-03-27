<#
.SYNOPSIS
    Writes a message wrapped with separator lines.
.PARAMETER Message
    The text to display.
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
        [Parameter(Mandatory, Position = 0)]
        [string] $Message,

        [int] $Width = 60,

        [System.ConsoleColor] $ForegroundColor = 'Blue'
    )

    $separator = '*' * $Width
    $output = "{0}`n{1}`n{2}" -f $separator, $Message, $separator

    Write-InformationColored $output -ForegroundColor $ForegroundColor
}
