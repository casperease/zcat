<#
.SYNOPSIS
    Redirects PowerShell's user module path from a network share to a local directory.
.DESCRIPTION
    Enterprise GPOs often redirect the Documents folder to a DFS/UNC share.
    PowerShell stores user modules under Documents\PowerShell\Modules (PS7)
    and Documents\WindowsPowerShell\Modules (WinPS 5.1), causing network
    scans on every module lookup, tab completion, and command discovery.

    This script applies three fixes:

    1. User-scope PSModulePath registry value — both PS7 and WinPS 5.1
       check this before using the Documents-based default. When set,
       the DFS path is never used. This also prevents the WinCompat
       layer (which starts a WinPS 5.1 background process) from
       re-introducing the DFS path into PS7's PSModulePath.

    2. powershell.config.json in $PSHOME — overrides PS7's user module
       path at the config level, before PSModulePath construction.

    3. Profile symlink — symlinks Documents\PowerShell to a local
       directory so $PROFILE resolves locally.

    All changes survive reboots and GPO refreshes — they're on the
    local disk, outside GPO-redirected folders.

    Requires Administrator. Run once — permanent until PS reinstall.
.EXAMPLE
    # Open PowerShell as Administrator, then:
    & 'C:\projects\zcap\automation\Zcap.Base\assets\Set-LocalPSModulePath.ps1'
#>

#Requires -RunAsAdministrator

$localPSHome = Join-Path $env:LOCALAPPDATA 'PowerShell'
$localModulePath = Join-Path $localPSHome 'Modules'
$networkPSHome = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell'

# --- 1. User-scope PSModulePath registry value ---
# Both PS7 and WinPS 5.1: "if User-scope PSModulePath exists, use it as defined."
# This prevents the Documents-based default AND stops the WinCompat layer's
# background WinPS 5.1 process from re-adding the DFS path.
$currentUserPath = [Environment]::GetEnvironmentVariable('PSModulePath', 'User')
if ($currentUserPath -ne $localModulePath) {
    if (-not (Test-Path $localModulePath)) {
        New-Item -Path $localModulePath -ItemType Directory -Force | Out-Null
    }
    [Environment]::SetEnvironmentVariable('PSModulePath', $localModulePath, 'User')
    Write-Host "User-scope PSModulePath registry value set to '$localModulePath'" -ForegroundColor Green
}
else {
    Write-Host "User-scope PSModulePath already configured" -ForegroundColor Green
}

# --- 2. powershell.config.json in $PSHOME ---
$configFile = Join-Path $PSHOME 'powershell.config.json'

if (Test-Path $configFile) {
    $config = Get-Content $configFile -Raw | ConvertFrom-Json
}
else {
    $config = [PSCustomObject]@{}
}

if ($config.PSModulePath -ne $localModulePath) {
    $config | Add-Member -NotePropertyName 'PSModulePath' -NotePropertyValue $localModulePath -Force
    $config | ConvertTo-Json -Depth 10 | Set-Content $configFile -Encoding UTF8
    Write-Host "powershell.config.json updated: PSModulePath = '$localModulePath'" -ForegroundColor Green
    Write-Host "  Config: $configFile" -ForegroundColor Gray
}
else {
    Write-Host "powershell.config.json already configured" -ForegroundColor Green
}

# --- 3. Profile symlink ---
if ($networkPSHome -notmatch '^\\\\') {
    Write-Host "Documents folder is local — no symlink needed" -ForegroundColor Green
    Write-Host ''
    Write-Host 'Restart PowerShell for changes to take effect.' -ForegroundColor Cyan
    exit
}

$item = Get-Item $networkPSHome -Force -ErrorAction Ignore
$alreadySymlinked = $item -and $item.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)

if ($alreadySymlinked) {
    Write-Host "Profile symlink already exists: $networkPSHome -> $($item.Target)" -ForegroundColor Green
}
else {
    if (Test-Path $networkPSHome) {
        Write-Host "Cannot create symlink — '$networkPSHome' already exists." -ForegroundColor Yellow
        Write-Host "Move or delete it manually, then rerun this script." -ForegroundColor Yellow
        Write-Host ''
        Write-Host 'Restart PowerShell for other changes to take effect.' -ForegroundColor Cyan
        exit
    }

    if (-not (Test-Path $localPSHome)) {
        New-Item -Path $localPSHome -ItemType Directory -Force | Out-Null
    }

    New-Item -ItemType SymbolicLink -Path $networkPSHome -Target $localPSHome | Out-Null
    Write-Host "Profile symlink created: $networkPSHome -> $localPSHome" -ForegroundColor Green
}

Write-Host ''
Write-Host 'Restart PowerShell for changes to take effect.' -ForegroundColor Cyan
