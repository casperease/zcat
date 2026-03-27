<#
.SYNOPSIS
    Throws if the current session is not running as Administrator.
.PARAMETER ErrorText
    Custom error message.
.EXAMPLE
    Assert-IsAdministrator
#>
function Assert-IsAdministrator {
    [CmdletBinding()]
    param(
        [string] $ErrorText = 'This operation requires Administrator privileges'
    )

    Assert-True (Test-IsAdministrator) -ErrorText $ErrorText
}
