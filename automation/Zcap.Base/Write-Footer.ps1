<#
.SYNOPSIS
    Writes a closing footer line using box-drawing characters.
.DESCRIPTION
    Renders a bottom closing line:
      ╰────────────────────╯
    Pairs with Write-Header to visually close a section.
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
        [int] $Width = 60,

        [System.ConsoleColor] $ForegroundColor
    )

    $inner = $Width - 2
    $bottomLine = "╰$('─' * $inner)╯"
    $colorSplat = if ($PSBoundParameters.ContainsKey('ForegroundColor')) { @{ ForegroundColor = $ForegroundColor } } else { @{} }

    Write-InformationColored $bottomLine @colorSplat
}
