[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Bootstrapper uses Write-Host for visible console output before module system is loaded')]
param(
    [switch] $ExportPrivates,
    [switch] $AllowWarnings,
    [switch] $IncludeWindowsPowerShell,
    [switch] $DiagnoseLoadTime
)

# Detect if running in a direct console session or from a script
$isConsoleSession = -not $MyInvocation.ScriptName

if ($isConsoleSession) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
}

if ($DiagnoseLoadTime) {
    $script:diagSw = [Diagnostics.Stopwatch]::StartNew()
    function script:Write-LoadTime ([string] $Step) {
        Write-Host ("{0,6}ms  {1}" -f [int]$script:diagSw.Elapsed.TotalMilliseconds, $Step) -ForegroundColor DarkGray
        $script:diagSw.Restart()
    }
}

# Configuration
$automationFolder = 'automation'
$vendorFolder = '.vendor'

# Global error handling — fail fast on errors and warnings by default
$global:ErrorActionPreference = 'Stop'
$global:WarningPreference = if ($AllowWarnings) { 'Continue' } else { 'Stop' }
$global:InformationPreference = 'Continue'

# Repository root reference
$env:RepositoryRoot = $PSScriptRoot
Write-Verbose "RepositoryRoot set to: $($env:RepositoryRoot)"

# Load resolver
$resolverModule = Join-Path $PSScriptRoot "$automationFolder/.resolver/Resolver.psm1"
Write-Verbose "Loading resolver from: $resolverModule"
Import-Module $resolverModule -Scope Global -Force
if ($DiagnoseLoadTime) { Write-LoadTime 'Resolver loaded' }

# Custom error view — shows ScriptStackTrace for unhandled errors
Update-FormatData -PrependPath (Join-Path $PSScriptRoot "$automationFolder/.resolver/ErrorView.format.ps1xml")

# Load vendored dependencies first
$vendorRoot = Join-Path $PSScriptRoot "$automationFolder/$vendorFolder"
Write-Verbose "Loading vendor modules from: $vendorRoot"
Import-VendorModules -VendorRoot $vendorRoot -Lazy 'Pester', 'PSScriptAnalyzer'
if ($DiagnoseLoadTime) { Write-LoadTime 'Vendor modules loaded' }

# Discover and import all modules
$modulesRoot = Join-Path $PSScriptRoot $automationFolder
Write-Verbose "Discovering modules in: $modulesRoot"
Import-AllModules -ModulesRoot $modulesRoot -ExportPrivates:$ExportPrivates
if ($DiagnoseLoadTime) { Write-LoadTime 'All modules loaded' }

# Clean up resolver — it has served its purpose
Write-Verbose 'Removing Resolver module'
Remove-Module Resolver -Force -ErrorAction SilentlyContinue

# Warn if PSModulePath contains a network share. The permanent fix is a one-time
# script that writes a local PSModulePath to the user-scope powershell.config.json.
# See: automation/Zcat.Utils/assets/README.md
if ($IsWindows) {
    $hasUncModulePath = ($env:PSModulePath -split [IO.Path]::PathSeparator) -match '^\\\\' | Select-Object -First 1

    if ($hasUncModulePath) {
        $fixScript = Join-Path $PSScriptRoot "$automationFolder/Zcat.Utils/assets/Set-LocalPSModulePath.ps1"
        Write-Host ''
        Write-Host 'WARNING: PSModulePath contains a network share.' -ForegroundColor Yellow
        Write-Host 'PowerShell will be slow — module lookups scan the network.' -ForegroundColor Yellow
        Write-Host "Run this once to fix:" -ForegroundColor Yellow
        Write-Host "  & '$fixScript'" -ForegroundColor Cyan
        Write-Host ''
    }
}

# Strict mode
Set-StrictMode -Version Latest

# Console session: load timer.
# In scripts, authors add `trap { Write-Exception $_; break }` after the importer.
if ($isConsoleSession) {
    if (Get-Command Write-Message -ErrorAction Ignore) {
        Write-Message "Loaded in $([math]::Round($sw.Elapsed.TotalSeconds, 1)) seconds"
    }
}
