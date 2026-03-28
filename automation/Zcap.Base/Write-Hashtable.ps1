<#
.SYNOPSIS
    Writes a hashtable as key = value pairs with a header and footer.
.PARAMETER Hashtable
    The hashtable to display.
.PARAMETER Name
    Label for the header. Defaults to 'Parameters'.
.PARAMETER ForegroundColor
    Color for the output. Defaults to Green.
.EXAMPLE
    Write-Hashtable @{ Path = './out'; Force = $true } -Name 'Copy params'
.EXAMPLE
    Write-Splat @{ Path = './out'; Force = $true }
#>
function Write-Hashtable {
    [Alias('Write-Splat')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [hashtable] $Hashtable,

        [Parameter(Position = 1)]
        [string] $Name = 'Parameters',

        [Alias('Color')]
        [System.ConsoleColor] $ForegroundColor = 'Green'
    )

    $header = "--- $Name ---"
    Write-InformationColored $header -ForegroundColor $ForegroundColor

    foreach ($key in $Hashtable.Keys | Sort-Object) {
        Write-InformationColored "$key = $($Hashtable[$key])" -ForegroundColor $ForegroundColor
    }

    Write-InformationColored ('-' * $header.Length) -ForegroundColor $ForegroundColor
}
