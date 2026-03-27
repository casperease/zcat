<#
.SYNOPSIS
    Writes an array with a named header and footer separator.
.PARAMETER Array
    The array to display.
.PARAMETER Name
    Label for the header. Defaults to 'Array'.
.PARAMETER ForegroundColor
    Color for the output. Defaults to Green.
.EXAMPLE
    Write-Array @('one', 'two', 'three') -Name 'Items'
#>
function Write-Array {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowEmptyCollection()]
        [object[]] $Array,

        [Parameter(Position = 1)]
        [string] $Name = 'Array',

        [Alias('Color')]
        [System.ConsoleColor] $ForegroundColor = 'Green'
    )

    $header = "--- $Name ---"
    Write-InformationColored $header -ForegroundColor $ForegroundColor

    foreach ($item in $Array) {
        Write-InformationColored "$item" -ForegroundColor $ForegroundColor
    }

    Write-InformationColored ('-' * $header.Length) -ForegroundColor $ForegroundColor
}
