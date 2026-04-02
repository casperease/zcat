<#
.SYNOPSIS
    Writes colored messages to the information stream.
.DESCRIPTION
    Like Write-Host but uses Write-Information internally, so output respects
    $InformationPreference and can be suppressed or redirected.

    Colors work in both interactive terminals and CI pipelines (ADO, GitHub
    Actions) because the message text contains ANSI escape sequences.
    Write-Host's -ForegroundColor uses the console API, which only works in
    interactive terminals — in CI stdout is a pipe and colors are lost.
    Embedding ANSI codes in the string itself ensures colors survive redirection.
.PARAMETER MessageData
    The message to write.
.PARAMETER ForegroundColor
    Text color. Defaults to the host's current foreground color.
.PARAMETER NoNewline
    Suppresses the trailing newline.
.EXAMPLE
    Write-InformationColored 'Build succeeded' -ForegroundColor Green
.EXAMPLE
    Write-InformationColored 'WARN' -ForegroundColor Yellow -NoNewline
#>
function Write-InformationColored {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [object] $MessageData,

        [System.ConsoleColor] $ForegroundColor,

        [switch] $NoNewline
    )

    $text = [string]$MessageData

    if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
        $ansi = switch ($ForegroundColor) {
            'Black'       { "`e[30m" }
            'DarkRed'     { "`e[31m" }
            'DarkGreen'   { "`e[32m" }
            'DarkYellow'  { "`e[33m" }
            'DarkBlue'    { "`e[34m" }
            'DarkMagenta' { "`e[35m" }
            'DarkCyan'    { "`e[36m" }
            'Gray'        { "`e[37m" }
            'DarkGray'    { "`e[90m" }
            'Red'         { "`e[91m" }
            'Green'       { "`e[92m" }
            'Yellow'      { "`e[93m" }
            'Blue'        { "`e[94m" }
            'Magenta'     { "`e[95m" }
            'Cyan'        { "`e[96m" }
            'White'       { "`e[97m" }
            default       { '' }
        }

        if ($ansi) {
            # Wrap each line individually — ADO/CI log renderers reset ANSI at newlines
            $lines = $text -split "`n"
            $text = ($lines | ForEach-Object { "${ansi}$_`e[0m" }) -join "`n"
        }
    }

    if ($NoNewline) {
        Write-Host $text -NoNewline
    }
    else {
        Write-Host $text
    }
}
