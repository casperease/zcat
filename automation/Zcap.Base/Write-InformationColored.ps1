<#
.SYNOPSIS
    Writes colored messages to the information stream.
.DESCRIPTION
    Like Write-Host but uses Write-Information internally, so output respects
    $InformationPreference and can be suppressed or redirected.
.PARAMETER MessageData
    The message to write.
.PARAMETER ForegroundColor
    Text color. Defaults to the host's current foreground color.
.PARAMETER BackgroundColor
    Background color. Defaults to the host's current background color.
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

        [System.ConsoleColor] $ForegroundColor = $Host.UI.RawUI.ForegroundColor,
        [System.ConsoleColor] $BackgroundColor = $Host.UI.RawUI.BackgroundColor,

        [switch] $NoNewline
    )

    $msg = [System.Management.Automation.HostInformationMessage]@{
        Message         = $MessageData
        ForegroundColor = $ForegroundColor
        BackgroundColor = $BackgroundColor
        NoNewline       = $NoNewline.IsPresent
    }

    $record = [System.Management.Automation.InformationRecord]::new($msg, $MyInvocation.PSCommandPath)
    $record.Tags.Add('PSHOST')
    $PSCmdlet.WriteInformation($record)
}
