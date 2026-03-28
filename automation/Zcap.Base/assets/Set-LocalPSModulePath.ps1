<#
.SYNOPSIS
    Redirects PowerShell's user module path from a network share to a local directory.
.DESCRIPTION
    Enterprise GPOs often redirect the Documents folder to a DFS/UNC share.
    PowerShell stores user modules under Documents\PowerShell\Modules (PS7)
    and Documents\WindowsPowerShell\Modules (WinPS 5.1), causing network
    scans on every module lookup, tab completion, and command discovery.

    This script applies three fixes:

    1. User-scope powershell.config.json — placed in the PS7 user config
       directory (Documents\PowerShell, even if on DFS). PS7 reads this
       single file at startup to override the CurrentUser module path.
       One file read is fast — the slowness comes from recursive module
       scanning, not reading a config file.

    2. AllUsers powershell.config.json in $PSHOME — overrides the AllUsers
       module path as a belt-and-suspenders measure.

    3. User-scope PSModulePath registry value — prevents WinPS 5.1
       (used by the WinCompat layer) from using the DFS-based default.

    No admin required for user-scope fixes. If running as Administrator,
    also writes the AllUsers config to $PSHOME. Run once.
.EXAMPLE
    & 'C:\projects\zcap\automation\Zcap.Base\assets\Set-LocalPSModulePath.ps1'
#>

$localModulePath = Join-Path $env:LOCALAPPDATA 'PowerShell' 'Modules'

if (-not (Test-Path $localModulePath)) {
    New-Item -Path $localModulePath -ItemType Directory -Force | Out-Null
}

# --- 1. User-scope powershell.config.json (CurrentUser module path) ---
# Use GetFolderPath, not $PROFILE — admin sessions resolve $PROFILE to a
# different (local) path than the normal user session (DFS).
$userConfigDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell'
if (-not (Test-Path $userConfigDir)) {
    New-Item -Path $userConfigDir -ItemType Directory -Force | Out-Null
}
$userConfigFile = Join-Path $userConfigDir 'powershell.config.json'

if (Test-Path $userConfigFile) {
    $userConfig = Get-Content $userConfigFile -Raw | ConvertFrom-Json
}
else {
    $userConfig = [PSCustomObject]@{}
}

if ($userConfig.PSModulePath -ne $localModulePath) {
    $userConfig | Add-Member -NotePropertyName 'PSModulePath' -NotePropertyValue $localModulePath -Force
    $userConfig | ConvertTo-Json -Depth 10 | Set-Content $userConfigFile -Encoding UTF8
    Write-Host "User-scope config: PSModulePath = '$localModulePath'" -ForegroundColor Green
    Write-Host "  File: $userConfigFile" -ForegroundColor Gray
}
else {
    Write-Host "User-scope config already set" -ForegroundColor Green
}

# --- 2. AllUsers powershell.config.json in $PSHOME (admin only) ---
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    $systemConfigFile = Join-Path $PSHOME 'powershell.config.json'

    if (Test-Path $systemConfigFile) {
        $systemConfig = Get-Content $systemConfigFile -Raw | ConvertFrom-Json
    }
    else {
        $systemConfig = [PSCustomObject]@{}
    }

    if ($systemConfig.PSModulePath -ne $localModulePath) {
        $systemConfig | Add-Member -NotePropertyName 'PSModulePath' -NotePropertyValue $localModulePath -Force
        $systemConfig | ConvertTo-Json -Depth 10 | Set-Content $systemConfigFile -Encoding UTF8
        Write-Host "AllUsers config: PSModulePath = '$localModulePath'" -ForegroundColor Green
        Write-Host "  File: $systemConfigFile" -ForegroundColor Gray
    }
    else {
        Write-Host "AllUsers config already set" -ForegroundColor Green
    }
}
else {
    Write-Host "Skipping AllUsers config (not admin). Run as Administrator to apply." -ForegroundColor Yellow
}

# --- 3. User-scope PSModulePath registry value (for WinPS 5.1 / WinCompat) ---
$currentUserPath = [Environment]::GetEnvironmentVariable('PSModulePath', 'User')
if ($currentUserPath -ne $localModulePath) {
    [Environment]::SetEnvironmentVariable('PSModulePath', $localModulePath, 'User')
    Write-Host "User-scope registry PSModulePath set to '$localModulePath'" -ForegroundColor Green
}
else {
    Write-Host "User-scope registry PSModulePath already set" -ForegroundColor Green
}

Write-Host ''
Write-Host 'Restart PowerShell for changes to take effect.' -ForegroundColor Cyan
