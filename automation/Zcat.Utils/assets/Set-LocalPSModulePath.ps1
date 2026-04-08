<#
.SYNOPSIS
    Redirects PowerShell 7's user module path from a network share to a local directory.
.DESCRIPTION
    Enterprise GPOs often redirect the Documents folder to a DFS/UNC share.
    PowerShell stores user modules under Documents\PowerShell\Modules,
    causing network scans on every module lookup, tab completion, and
    command discovery.

    This script writes a user-scope powershell.config.json in the PS7
    user config directory (Documents\PowerShell, even if on DFS). PS7
    reads this single file at startup to override the CurrentUser module
    path. One file read is fast — the slowness comes from recursive
    module scanning, not reading a config file.

    No admin required. Idempotent — safe to run repeatedly.
.EXAMPLE
    & 'automation\Zcat.Utils\assets\Set-LocalPSModulePath.ps1'
#>

$localModulePath = Join-Path $env:LOCALAPPDATA 'PowerShell' 'Modules'

if (-not (Test-Path $localModulePath)) {
    New-Item -Path $localModulePath -ItemType Directory -Force | Out-Null
}

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
    Write-Host "PSModulePath set to '$localModulePath'" -ForegroundColor Green
    Write-Host "  Config: $userConfigFile" -ForegroundColor Gray
}
else {
    Write-Host "PSModulePath already configured" -ForegroundColor Green
}

# --- Check for modules left on DFS that should be moved ---
$dfsModulePath = Join-Path $userConfigDir 'Modules'
if ((Test-Path $dfsModulePath) -and (Get-ChildItem $dfsModulePath -Directory -ErrorAction Ignore)) {
    Write-Host ''
    Write-Host "You have modules at '$dfsModulePath' (DFS)." -ForegroundColor Yellow
    Write-Host "Move them to the new local path to avoid stale copies:" -ForegroundColor Yellow
    Write-Host "  Move-Item '$dfsModulePath\*' '$localModulePath' -Force" -ForegroundColor Cyan
}

Write-Host ''
Write-Host 'Restart PowerShell for changes to take effect.' -ForegroundColor Cyan
