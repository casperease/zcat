<#
.SYNOPSIS
    Asserts all tools are available at the correct version.
.DESCRIPTION
    Calls Get-WorkstationToolsStatus and throws if any tool is Missing or WrongVersion.
    Tools with status OK or Usable pass — the tool works regardless of how
    it was installed. Chocolatey status is ignored.
.EXAMPLE
    Assert-WorkstationToolsStatus
#>
function Assert-WorkstationToolsStatus {
    [CmdletBinding()]
    param()

    $status = Get-WorkstationToolsStatus
    $failures = @($status | Where-Object { $_.Status -in 'Missing', 'WrongVersion' })

    if ($failures) {
        $details = ($failures | ForEach-Object {
            "  $($_.Tool): expected $($_.Locked), found $(if ($_.Installed) { $_.Installed } else { 'not installed' }) — $($_.Action)"
        }) -join "`n"
        throw "Tools not ready. Run Install-WorkstationTools to fix.`n`n$details"
    }
}
