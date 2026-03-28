<#
.SYNOPSIS
    Repairs PowerShellGet and PackageManagement after a broken module path.
.DESCRIPTION
    Downloads PackageManagement and PowerShellGet directly from the
    PowerShell Gallery (no Install-Module needed) and places them in
    the user module path. Also installs NuGet provider and PSReadLine.

    Run this if Install-Module fails with NuGet provider errors or
    PackageManagement type initializer exceptions.

    No admin required.
.EXAMPLE
    & 'automation\Zcap.Base\assets\Repair-PSModules.ps1'
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$modulePath = Join-Path $env:LOCALAPPDATA 'PowerShell' 'Modules'
if (-not (Test-Path $modulePath)) {
    New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
}

$tempDir = Join-Path ([IO.Path]::GetTempPath()) 'ps-module-repair'
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

function Install-ModuleFromGallery {
    param(
        [string] $Name,
        [string] $Version
    )

    $destDir = Join-Path $modulePath $Name $Version
    if (Test-Path $destDir) {
        Write-Host "  $Name $Version already installed" -ForegroundColor Gray
        return
    }

    $nupkg = Join-Path $tempDir "$Name.nupkg"
    $zip = Join-Path $tempDir "$Name.zip"
    $extractDir = Join-Path $tempDir "$Name-extracted"

    Write-Host "  Downloading $Name $Version..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://www.powershellgallery.com/api/v2/package/$Name/$Version" -OutFile $nupkg
    Copy-Item $nupkg $zip -Force
    Expand-Archive $zip -DestinationPath $extractDir -Force

    New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    Get-ChildItem $extractDir -Exclude '_rels', 'package', '[Content_Types].xml', '*.nuspec' |
        Copy-Item -Destination $destDir -Recurse -Force

    Write-Host "  $Name $Version installed to '$destDir'" -ForegroundColor Green
}

Write-Host 'Repairing PowerShell module infrastructure...' -ForegroundColor Yellow
Write-Host ''

Install-ModuleFromGallery -Name 'PackageManagement' -Version '1.4.8.1'
Install-ModuleFromGallery -Name 'PowerShellGet' -Version '2.2.5'
Install-ModuleFromGallery -Name 'PSReadLine' -Version '2.4.0'

# Cleanup
Remove-Item $tempDir -Recurse -Force -ErrorAction Ignore

Write-Host ''
Write-Host 'Done. Restart PowerShell, then verify:' -ForegroundColor Green
Write-Host '  Install-Module -Name Az.Accounts -WhatIf   # should not error' -ForegroundColor Cyan
Write-Host '  (Get-Module PSReadLine).Version             # should be 2.4.0' -ForegroundColor Cyan
