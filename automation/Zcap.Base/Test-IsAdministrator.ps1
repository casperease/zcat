<#
.SYNOPSIS
    Returns true if the current session is running as Administrator (Windows) or root (Linux/macOS).
.EXAMPLE
    Test-IsAdministrator
#>
function Test-IsAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($IsWindows) {
        $user = [Security.Principal.WindowsIdentity]::GetCurrent()
        (New-Object Security.Principal.WindowsPrincipal $user).IsInRole(
            [Security.Principal.WindowsBuiltinRole]::Administrator
        )
    }
    else {
        (id -u) -eq '0'
    }
}
