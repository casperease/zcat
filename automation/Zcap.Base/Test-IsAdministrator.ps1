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
        # Root or has passwordless sudo (CI agents, containers)
        if ((id -u) -eq '0') { return $true }
        try {
            $result = sudo -n true 2>&1
            $LASTEXITCODE -eq 0
        }
        catch {
            $false
        }
    }
}
