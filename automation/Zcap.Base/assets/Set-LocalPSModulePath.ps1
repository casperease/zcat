<#
.SYNOPSIS
    Redirects PowerShell's user module path from a network share to a local directory.
.DESCRIPTION
    Enterprise GPOs often redirect the Documents folder to a DFS/UNC share.
    PowerShell stores user modules under Documents\PowerShell\Modules (PS7)
    and Documents\WindowsPowerShell\Modules (WinPS 5.1), causing network
    scans on every module lookup, tab completion, and command discovery.

    This script writes a user-scope powershell.config.json in the PS7
    user config directory (Documents\PowerShell, even if on DFS). PS7
    reads this single file at startup to override the CurrentUser module
    path. One file read is fast — the slowness comes from recursive
    module scanning, not reading a config file.

    Also cleans up damage from previous versions of this script:
    removes PSModulePath from $PSHOME config and User-scope registry
    (both break core module discovery).

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

# --- 2. Clean up AllUsers config from previous version of this script ---
# Setting PSModulePath in $PSHOME overrides AllUsers paths including
# $PSHOME\Modules, which breaks core PS7 modules. Remove it.
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$systemConfigFile = Join-Path $PSHOME 'powershell.config.json'

if ($isAdmin -and (Test-Path $systemConfigFile)) {
    $systemConfig = Get-Content $systemConfigFile -Raw | ConvertFrom-Json
    if ($systemConfig.PSModulePath) {
        $systemConfig.PSObject.Properties.Remove('PSModulePath')
        $remaining = $systemConfig.PSObject.Properties | Measure-Object
        if ($remaining.Count -eq 0) {
            Remove-Item $systemConfigFile -Force
            Write-Host "Removed $systemConfigFile (was only PSModulePath)" -ForegroundColor Yellow
        }
        else {
            $systemConfig | ConvertTo-Json -Depth 10 | Set-Content $systemConfigFile -Encoding UTF8
            Write-Host "Removed PSModulePath from $systemConfigFile" -ForegroundColor Yellow
        }
    }
}

# --- 3. Clean up User-scope PSModulePath registry value ---
# Setting this causes PS7 to skip appending $PSHOME\Modules (core modules).
# The user-scope powershell.config.json handles our needs without this side effect.
$currentUserPath = [Environment]::GetEnvironmentVariable('PSModulePath', 'User')
if ($currentUserPath) {
    [Environment]::SetEnvironmentVariable('PSModulePath', $null, 'User')
    Write-Host "Removed User-scope registry PSModulePath (was: '$currentUserPath')" -ForegroundColor Yellow
}
else {
    Write-Host "User-scope registry PSModulePath clean" -ForegroundColor Green
}

Write-Host ''
Write-Host 'Restart PowerShell for changes to take effect.' -ForegroundColor Cyan
