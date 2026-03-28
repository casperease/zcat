[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Bootstrapper uses Write-Host for visible console output before module system is loaded')]
param(
    [switch] $ExportPrivates,
    [switch] $AllowWarnings,
    [switch] $IncludeWindowsPowerShell
)

# Detect if running in a direct console session or from a script
$isConsoleSession = -not $MyInvocation.ScriptName

if ($isConsoleSession) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
}

# Strip PSModulePath to local system paths only.
# Enterprise environments often redirect $HOME\Documents to DFS/UNC shares via GPO.
# PowerShell includes Documents\PowerShell\Modules in PSModulePath by default,
# causing every module lookup, tab completion, and auto-load to scan the network.
# We vendor all dependencies — the user profile module path is never needed.
#
# This runtime fix helps the current session. For a permanent fix that survives
# PS7 internal PSModulePath reconstruction (WinCompat, auto-loading), run
# the Set-LocalPSModulePath script as Administrator (one-time).
$sep = [System.IO.Path]::PathSeparator
$script:CleanPSModulePath = @(
    (Join-Path $PSHOME 'Modules')                                                                 # pwsh built-in modules
    (Join-Path ([Environment]::GetFolderPath('ProgramFiles')) 'PowerShell' 'Modules')             # system-wide PS 7 modules
    # Windows-only modules that don't ship with PS 7 (e.g., Appx, DISM, NetAdapter, Hyper-V)
    if ($IncludeWindowsPowerShell -and $IsWindows) {
        (Join-Path $env:SystemRoot 'system32' 'WindowsPowerShell' 'v1.0' 'Modules')               # Windows built-in modules
        (Join-Path ([Environment]::GetFolderPath('ProgramFiles')) 'WindowsPowerShell' 'Modules')   # system-wide PS 5.1 modules
    }
) -join $sep
$env:PSModulePath = $script:CleanPSModulePath
Write-Verbose "PSModulePath set to: $($env:PSModulePath)"


# Bootstrap base modules
Import-Module Microsoft.PowerShell.Management -ErrorAction SilentlyContinue
Import-Module Microsoft.PowerShell.Security -ErrorAction SilentlyContinue
Import-Module Microsoft.PowerShell.Utility -ErrorAction SilentlyContinue

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

# Load vendored dependencies first
$vendorRoot = Join-Path $PSScriptRoot "$automationFolder/$vendorFolder"
Write-Verbose "Loading vendor modules from: $vendorRoot"
Import-VendorModules -VendorRoot $vendorRoot -Lazy 'Pester', 'PSScriptAnalyzer'

# Discover and import all modules
$modulesRoot = Join-Path $PSScriptRoot $automationFolder
Write-Verbose "Discovering modules in: $modulesRoot"
Import-AllModules -ModulesRoot $modulesRoot -ExportPrivates:$ExportPrivates

# Clean up resolver — it has served its purpose
Write-Verbose 'Removing Resolver module'
Remove-Module Resolver -Force -ErrorAction SilentlyContinue

# Re-apply clean PSModulePath — imports above can trigger the WinCompat layer
# which re-adds DFS/UNC user paths. Strip them again.
$env:PSModulePath = $script:CleanPSModulePath

# Warn if the default user module path points to a network share. This causes
# PS7 to scan the network during internal PSModulePath reconstruction (WinCompat,
# auto-loading) even after our runtime strip. The permanent fix is a one-time
# admin script that redirects the PS7 user module path to a local directory.
if ($IsWindows) {
    $docsFolder = [Environment]::GetFolderPath('MyDocuments')
    $configFile = Join-Path $PSHOME 'powershell.config.json'
    $fixApplied = try { (Test-Path $configFile) -and ((Get-Content $configFile -Raw | ConvertFrom-Json).PSModulePath) } catch { $false }

    if ($docsFolder -match '^\\\\' -and -not $fixApplied) {
        $fixScript = Join-Path $PSScriptRoot "$automationFolder/Zcap.Base/assets/Set-LocalPSModulePath.ps1"
        Write-Host ''
        Write-Host 'WARNING: Your Documents folder is on a network share.' -ForegroundColor Yellow
        Write-Host 'PowerShell will be slow — module lookups scan the network.' -ForegroundColor Yellow
        Write-Host "Open PowerShell as Administrator and run:" -ForegroundColor Yellow
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
                            } else { 'at <prompt>' }
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
