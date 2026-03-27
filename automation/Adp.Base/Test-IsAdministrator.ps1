<#
.SYNOPSIS
    Returns true if the current session is running as Administrator.
.EXAMPLE
    Test-IsAdministrator
#>
function Test-IsAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Assert-True $IsWindows -ErrorText 'Test-IsAdministrator is only supported on Windows'

    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole(
        [Security.Principal.WindowsBuiltinRole]::Administrator
    )
}
