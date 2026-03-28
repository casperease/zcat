<#
.SYNOPSIS
    Redirects PowerShell 7's user directory from a network share to a local path.
.DESCRIPTION
    Enterprise GPOs often redirect the Documents folder to a DFS/UNC share.
    PowerShell 7 stores its user profile and modules under Documents\PowerShell,
    causing network scans on every module lookup, tab completion, and startup.

    This script fixes both problems in one shot:

    1. PSModulePath override — writes powershell.config.json in $PSHOME with a
       local user module path. PS7 reads this BEFORE constructing PSModulePath,
       so the network path never enters the module search.

    2. Profile symlink — creates a directory symlink from the DFS-based
       Documents\PowerShell to a local directory. $PROFILE, profile scripts,
       and any code using the Documents\PowerShell path transparently resolve
       to the local directory. Existing content is migrated.

    Both changes survive reboots and GPO refreshes — $PSHOME and the symlink
    are on the local disk, outside GPO-redirected folders.

    Requires Administrator (writes to $PSHOME, creates symlinks).
    Run once — the fix is permanent until PowerShell is reinstalled.
.EXAMPLE
    Start-Process pwsh -Verb RunAs -ArgumentList '-File', 'automation\Zcap.Base\assets\Set-LocalPSModulePath.ps1'
#>

#Requires -RunAsAdministrator

$localPSHome = Join-Path $env:LOCALAPPDATA 'PowerShell'
$localModulePath = Join-Path $localPSHome 'Modules'
$networkPSHome = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell'

# --- 1. PSModulePath config override ---

$configFile = Join-Path $PSHOME 'powershell.config.json'

if (Test-Path $configFile) {
    $config = Get-Content $configFile -Raw | ConvertFrom-Json
}
else {
    $config = [PSCustomObject]@{}
}

if ($config.PSModulePath -ne $localModulePath) {
    if (-not (Test-Path $localModulePath)) {
        New-Item -Path $localModulePath -ItemType Directory -Force | Out-Null
    }
    $config | Add-Member -NotePropertyName 'PSModulePath' -NotePropertyValue $localModulePath -Force
    $config | ConvertTo-Json -Depth 10 | Set-Content $configFile -Encoding UTF8
    Write-Host "PSModulePath set to '$localModulePath'" -ForegroundColor Green
    Write-Host "  Config: $configFile" -ForegroundColor Gray
}
else {
    Write-Host "PSModulePath already configured" -ForegroundColor Green
}

# --- 2. Profile symlink ---

# Skip if Documents\PowerShell is already a symlink or doesn't point to a network path
if ($networkPSHome -notmatch '^\\\\') {
    Write-Host "Documents folder is local — no symlink needed" -ForegroundColor Green
    Write-Host ''
    Write-Host 'Restart PowerShell for changes to take effect.' -ForegroundColor Cyan
    return
}

$item = Get-Item $networkPSHome -Force -ErrorAction Ignore
$alreadySymlinked = $item -and $item.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)

if ($alreadySymlinked) {
    Write-Host "Profile symlink already exists: $networkPSHome -> $($item.Target)" -ForegroundColor Green
}
else {
    # Ensure local directory exists
    if (-not (Test-Path $localPSHome)) {
        New-Item -Path $localPSHome -ItemType Directory -Force | Out-Null
    }

    # Migrate existing content from network to local
    if (Test-Path $networkPSHome) {
        $existingFiles = Get-ChildItem $networkPSHome -Force -ErrorAction Ignore
        if ($existingFiles) {
            Write-Host "Migrating existing files from '$networkPSHome' to '$localPSHome'" -ForegroundColor Yellow
            foreach ($f in $existingFiles) {
                $dest = Join-Path $localPSHome $f.Name
                if (-not (Test-Path $dest)) {
                    Move-Item $f.FullName $dest -Force
                }
            }
        }
        Remove-Item $networkPSHome -Force -Recurse
    }

    # Create symlink: Documents\PowerShell -> LOCALAPPDATA\PowerShell
    New-Item -ItemType SymbolicLink -Path $networkPSHome -Target $localPSHome | Out-Null
    Write-Host "Profile symlink created:" -ForegroundColor Green
    Write-Host "  $networkPSHome -> $localPSHome" -ForegroundColor Green
}

Write-Host ''
Write-Host 'Restart PowerShell for changes to take effect.' -ForegroundColor Cyan
