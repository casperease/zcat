<#
.SYNOPSIS
    Uninstalls Chocolatey from the current machine.
.DESCRIPTION
    Removes the Chocolatey package manager if it is installed.
    Idempotent — safe to run when Chocolatey is not present.
    Windows-only; returns immediately on other platforms.
.EXAMPLE
    Uninstall-Chocolatey
#>
function Uninstall-Chocolatey {
    [CmdletBinding()]
    param()

    if (-not $IsWindows) {
        Write-Verbose 'Chocolatey is Windows-only, nothing to do'
        return
    }

    if (-not (Test-Command choco)) {
        Write-Verbose 'Chocolatey is not installed'
        return
    }

    Assert-IsAdministrator 'Uninstall-Chocolatey requires Administrator privileges'

    $chocoDir = if ($env:ChocolateyInstall) { $env:ChocolateyInstall }
                else { Join-Path $env:SystemDrive 'ProgramData' 'chocolatey' }

    Assert-PathExist $chocoDir

    # Remove Chocolatey directory
    Write-Verbose "Removing Chocolatey directory: $chocoDir"
    Remove-Item $chocoDir -Recurse -Force
    # Remove environment variable
    Write-Verbose 'Removing ChocolateyInstall environment variable'
    [System.Environment]::SetEnvironmentVariable('ChocolateyInstall', $null, 'Machine')
    [System.Environment]::SetEnvironmentVariable('ChocolateyInstall', $null, 'User')

    # Remove Chocolatey from PATH
    foreach ($scope in 'Machine', 'User') {
        $path = [System.Environment]::GetEnvironmentVariable('PATH', $scope)
        if (-not $path) { continue }
        $cleaned = ($path -split ';' | Where-Object { $_ -notmatch 'chocolatey' }) -join ';'
        if ($cleaned -ne $path) {
            Write-Verbose "Removing Chocolatey from $scope PATH"
            [System.Environment]::SetEnvironmentVariable('PATH', $cleaned, $scope)
        }
    }

    Write-Message 'Chocolatey uninstalled'
}
