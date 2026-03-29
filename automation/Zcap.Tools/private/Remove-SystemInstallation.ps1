<#
.SYNOPSIS
    Removes an installation directory and cleans it from system PATH.
.DESCRIPTION
    Private helper for Remove-NodeJs, Remove-Python, etc. Deletes the
    directory, removes matching entries from the system PATH registry
    key, clears specified environment variables, and broadcasts
    WM_SETTINGCHANGE. Windows-only.
.PARAMETER InstallDir
    Resolved absolute path to the installation directory.
.PARAMETER ExtraPathDirs
    Subdirectory names under InstallDir that are also on PATH
    (e.g. 'Scripts' for Python, 'wbin' for AzCli).
.PARAMETER EnvironmentVariables
    System-level environment variable names to clear.
#>
function Remove-SystemInstallation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $InstallDir,

        [string[]] $ExtraPathDirs = @(),

        [string[]] $EnvironmentVariables = @()
    )

    # Delete the directory
    Remove-Item -Path $InstallDir -Recurse -Force

    # Build list of paths to remove from system PATH
    $removePaths = @($InstallDir)
    foreach ($sub in $ExtraPathDirs) {
        $removePaths += Join-Path $InstallDir $sub
    }

    # Clean system PATH
    $regKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
    $currentPath = (Get-ItemProperty -Path $regKey -Name Path).Path
    $entries = $currentPath -split ';' | Where-Object { $_ -ne '' }
    $filtered = $entries | Where-Object {
        [System.IO.Path]::GetFullPath($_) -notin $removePaths
    }

    $pathChanged = $filtered.Count -lt $entries.Count
    if ($pathChanged) {
        Set-ItemProperty -Path $regKey -Name Path -Value ($filtered -join ';')
    }

    # Clear environment variables
    foreach ($var in $EnvironmentVariables) {
        $value = [Environment]::GetEnvironmentVariable($var, 'Machine')
        if ($null -ne $value) {
            [Environment]::SetEnvironmentVariable($var, $null, 'Machine')
        }
    }

    # Broadcast WM_SETTINGCHANGE so running Explorer/shells pick up the change
    if ($pathChanged -or $EnvironmentVariables.Count -gt 0) {
        if (-not ('Win32.NativeMethods' -as [type])) {
            Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(
    IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
    uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
        }
        $result = [UIntPtr]::Zero
        [Win32.NativeMethods]::SendMessageTimeout(
            [IntPtr]0xffff, 0x001A, [UIntPtr]::Zero,
            'Environment', 0x0002, 5000, [ref]$result
        ) | Out-Null
    }

    return $pathChanged
}
