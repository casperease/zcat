<#
.SYNOPSIS
    Writes a closing footer line in a chosen style.
.DESCRIPTION
    Pairs with Write-Header to visually close a section.
    Renders a single closing line matching the header style:
      Curved:  ╰──────────────╯
      Stars:   ****************
      Heavy:   ╚══════════════╝
.PARAMETER Style
    Visual style: Curved, Stars, or Heavy. Defaults to Curved.
.PARAMETER Width
    Total width of the line. Defaults to 60.
.PARAMETER ForegroundColor
    Color for the output. No color by default (renders as terminal default).
.EXAMPLE
    Write-Header 'Deploying'
    Deploy-App
    Write-Footer
#>
function Write-Footer {
    [CmdletBinding()]
    param(
        [ValidateSet('Curved', 'Stars', 'Heavy')]
        [string] $Style = 'Curved',

        [int] $Width = 60,

        [System.ConsoleColor] $ForegroundColor
    )

    $colorSplat = if ($PSBoundParameters.ContainsKey('ForegroundColor')) { @{ ForegroundColor = $ForegroundColor } } else { @{} }

    $line = switch ($Style) {
        'Curved' { $inner = $Width - 2; "`n╰$('─' * $inner)╯" }
        'Stars'  { '*' * $Width }
        'Heavy' { $inner = $Width - 2; "╚$('═' * $inner)╝" }
    }

    Write-InformationColored $line @colorSplat
}
