<#
.SYNOPSIS
    Asserts all devbox tools are available at the correct version.
.DESCRIPTION
    Calls Get-DevBoxStatus and throws if any tool is Missing or WrongVersion.
    Tools with status OK or Usable pass — the tool works regardless of how
    it was installed. Chocolatey status is ignored.
.EXAMPLE
    Assert-DevBoxStatus
#>
function Assert-DevBoxStatus {
    [CmdletBinding()]
    param()

    $status = Get-DevBoxStatus
    $failures = @($status | Where-Object { $_.Status -in 'Missing', 'WrongVersion' })

    if ($failures) {
        $details = ($failures | ForEach-Object {
            "  $($_.Tool): expected $($_.Locked), found $(if ($_.Installed) { $_.Installed } else { 'not installed' }) — $($_.Action)"
        }) -join "`n"
        throw "DevBox tools not ready. Run Install-DevBox to fix.`n`n$details"
    }
}
