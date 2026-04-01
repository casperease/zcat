<#
.SYNOPSIS
    Asserts all tools are available at the correct version.
.DESCRIPTION
    Calls Get-DevBoxToolsStatus and throws if any tool is Missing or WrongVersion.
    Tools with status OK or Usable pass — the tool works regardless of how
    it was installed. Chocolatey status is ignored.
.EXAMPLE
    Assert-DevBoxToolsStatus
#>
function Assert-DevBoxToolsStatus {
    [CmdletBinding()]
    param()

    $status = Get-DevBoxToolsStatus
    $failures = @($status | Where-Object { $_.Status -in 'Missing', 'WrongVersion' })

    if ($failures) {
        $details = ($failures | ForEach-Object {
            "  $($_.Tool): expected $($_.Locked), found $(if ($_.Installed) { $_.Installed } else { 'not installed' }) — $($_.Action)"
        }) -join "`n"
        throw "Tools not ready. Run Install-DevBoxTools to fix.`n`n$details"
    }
}
