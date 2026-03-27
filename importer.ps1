[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
param(
    [switch] $ExportPrivates,
    [switch] $AllowWarnings
)

# Detect if called from an interactive prompt or from a script
$isInteractive = -not $MyInvocation.ScriptName

if ($isInteractive) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
}

# Bootstrap base modules
Import-Module Microsoft.PowerShell.Management -ErrorAction SilentlyContinue
Import-Module Microsoft.PowerShell.Security -ErrorAction SilentlyContinue
Import-Module Microsoft.PowerShell.Utility -ErrorAction SilentlyContinue

# Configuration
$automationFolder = 'automation'
$vendorFolder = '.vendor'

# Global error handling — fail fast on errors and warnings by default
$ErrorActionPreference = 'Stop'
$WarningPreference = if ($AllowWarnings) { 'Continue' } else { 'Stop' }
$InformationPreference = 'Continue'

# Repository root reference
$env:RepositoryRoot = $PSScriptRoot

# Load resolver
$resolverModule = Join-Path $PSScriptRoot "$automationFolder/.resolver/Resolver.psm1"
Import-Module $resolverModule -Scope Global -Force

# Load vendored dependencies first
$vendorRoot = Join-Path $PSScriptRoot "$automationFolder/$vendorFolder"
Import-VendorModules -VendorRoot $vendorRoot -Lazy 'Pester', 'PSScriptAnalyzer'

# Discover and import all modules
$modulesRoot = Join-Path $PSScriptRoot $automationFolder
Import-AllModules -ModulesRoot $modulesRoot -ExportPrivates:$ExportPrivates

# Clean up resolver — it has served its purpose
Remove-Module Resolver -Force -ErrorAction SilentlyContinue

# Strict mode
Set-StrictMode -Version Latest

# Interactive-only: prompt hook and load timer
# In scripts, authors add `trap { Write-Exception $_; break }` after the importer.
if ($isInteractive) {
    # Switch to CategoryView (minimal three-liner) because our prompt
    # hook replaces it with a full stack trace via Write-Exception.
    $global:ErrorView = 'CategoryView'
    function global:prompt {
        # Only show diagnostics when the last command failed ($? is $false)
        # Skip errors caught by Pester's Should -Throw (expected throws during testing)
        if (-not $? -and $global:Error.Count -gt 0) {
            $trace = $global:Error[0].ScriptStackTrace
            if ($trace -notmatch 'Should-Throw,.+Pester\.psm1') {
                if (Get-Command Write-Exception -ErrorAction Ignore) {
                    Write-Exception $global:Error[0]
                } else {
                    Write-Host $global:Error[0].Exception.Message
                }
            }
        }
        "PS $($executionContext.SessionState.Path.CurrentLocation)> "
    }

    if (Get-Command Write-Message -ErrorAction Ignore) {
        Write-Message "Loaded in $([math]::Round($sw.Elapsed.TotalSeconds, 1)) seconds"
    }
}
