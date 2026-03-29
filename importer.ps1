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

# Warn if the default user module path points to a network share. This causes
# PS7 to scan the network during internal PSModulePath reconstruction (WinCompat,
# auto-loading) even after our runtime strip. The permanent fix is a one-time
# admin script that redirects the PS7 user module path to a local directory.
if ($IsWindows) {
    $hasUncModulePath = ($env:PSModulePath -split [IO.Path]::PathSeparator) -match '^\\\\' | Select-Object -First 1

    if ($hasUncModulePath) {
        $fixScript = Join-Path $PSScriptRoot "$automationFolder/Zcap.Base/assets/Set-LocalPSModulePath.ps1"
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

# Console session: prompt hook and load timer.
# In scripts, authors add `trap { Write-Exception $_; break }` after the importer.
if ($isConsoleSession) {
    # Default ConciseView handles external errors natively. The prompt hook adds
    # Write-Exception with full stack trace for errors from our modules only.
    function global:prompt {
        # The prompt must never throw — a crashing prompt destroys the console session.
        if (-not $? -and $global:Error.Count -gt 0) {
            try {
                $err = $global:Error[0]
                $record = if ($err -is [System.Management.Automation.ErrorRecord]) { $err } else { $null }
                $trace = if ($record -and $record.psobject.Properties['ScriptStackTrace']) { $record.ScriptStackTrace } else { '' }

                $isOurError = $trace -and $trace -match [regex]::Escape($env:RepositoryRoot)
                $isPesterExpected = $trace -and $trace -match 'Should-Throw,.+Pester\.psm1'

                if ($isOurError -and -not $isPesterExpected) {
                    Write-Host ('─' * 60) -ForegroundColor DarkGray
                    $traceLines = $trace -split "`n"
                    $formatted = $traceLines | ForEach-Object {
                        if ($_ -match 'at <ScriptBlock>, <No file>: line \d+') {
                            $lastCmd = (Get-History -Count 1).CommandLine
                            if ($lastCmd) {
                                $lastCmd = ($lastCmd -replace '[\r\n]+', ' ').Trim()
                                if ($lastCmd.Length -gt 30) { $lastCmd = $lastCmd.Substring(0, 30) + '...' }
                                "at $lastCmd"
                            }
                            else { 'at <prompt>' }
                        }
                        else { $_ }
                    }
                    Write-Host ($formatted -join "`n") -ForegroundColor Red
                }
            }
            catch {
                try { Write-Host $global:Error[0].Message -ForegroundColor Red } catch { }
            }
        }
        "PS $($executionContext.SessionState.Path.CurrentLocation)> "
    }

    if (Get-Command Write-Message -ErrorAction Ignore) {
        Write-Message "Loaded in $([math]::Round($sw.Elapsed.TotalSeconds, 1)) seconds"
    }
}
