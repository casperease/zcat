<#
.SYNOPSIS
    Redirects PowerShell 7's user directory from a network share to a local path.
.DESCRIPTION
    Enterprise GPOs redirect the Documents folder to a DFS/UNC share.
    PowerShell stores its user config, profile, and modules under
    Documents\PowerShell, causing network scans on every module lookup.

    This script:
    1. Creates a local PowerShell directory at LOCALAPPDATA\PowerShell
    2. Replaces Documents\PowerShell with a symlink to the local directory
    3. Sets execution policy to Bypass for CurrentUser (required — both
       DFS and symlinked profiles are treated as "remote" by RemoteSigned)

    The symlink makes $PROFILE, powershell.config.json, and user modules
    all resolve locally. No admin required. Idempotent.
.EXAMPLE
    & 'automation\Zcap.Base\assets\Set-LocalPSModulePath.ps1'
#>

$localPSDir = Join-Path $env:LOCALAPPDATA 'PowerShell'
$localModulePath = Join-Path $localPSDir 'Modules'
$networkPSDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell'

# Skip if Documents is already local
if ($networkPSDir -notmatch '^\\\\') {
    Write-Host "Documents folder is local — no fix needed" -ForegroundColor Green
    exit
}

# --- 1. Ensure local directory exists ---
if (-not (Test-Path $localPSDir)) {
    New-Item -Path $localPSDir -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path $localModulePath)) {
    New-Item -Path $localModulePath -ItemType Directory -Force | Out-Null
}

# --- 2. Symlink Documents\PowerShell → local ---
$item = Get-Item $networkPSDir -Force -ErrorAction Ignore
$alreadySymlinked = $item -and $item.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)

if ($alreadySymlinked) {
    Write-Host "Symlink already exists: $networkPSDir -> $($item.Target)" -ForegroundColor Green
}
else {
    if (Test-Path $networkPSDir) {
        Write-Host "Cannot create symlink — '$networkPSDir' already exists on DFS." -ForegroundColor Yellow
        Write-Host "Move or delete it, then rerun this script." -ForegroundColor Yellow
        exit
    }

    New-Item -ItemType SymbolicLink -Path $networkPSDir -Target $localPSDir | Out-Null
    Write-Host "Symlink created: $networkPSDir -> $localPSDir" -ForegroundColor Green
}

# --- 3. Execution policy ---
# Both DFS-hosted and symlinked profiles are treated as "remote" by
# RemoteSigned. Bypass at CurrentUser scope allows the profile to load.
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -ne 'Bypass') {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
    Write-Host "Execution policy set to Bypass (CurrentUser)" -ForegroundColor Green
}
else {
    Write-Host "Execution policy already Bypass" -ForegroundColor Green
}

Write-Host ''
Write-Host 'Restart PowerShell for changes to take effect.' -ForegroundColor Cyan
