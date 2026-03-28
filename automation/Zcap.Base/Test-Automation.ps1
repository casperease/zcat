<#
.SYNOPSIS
    Runs all Pester tests found across automation modules.
.PARAMETER Level
    Maximum test level to run. Defaults to 1.
    L0 = fast unit tests (< 400ms), L1 = unit tests (< 2s), L2 = integration tests (> 2s, may have deps).
    Level 1 runs L0 + L1. Level 2 runs L0 + L1 + L2.
.PARAMETER Output
    Pester output verbosity level. Defaults to 'Normal'.
.PARAMETER PassThru
    Returns the Pester result object. By default, no object is returned.
.EXAMPLE
    Test-Automation
.EXAMPLE
    Test-Automation -Level 2
.EXAMPLE
    Test-Automation -Output Detailed -PassThru
#>
function Test-Automation {
    [CmdletBinding()]
    param(
        [ValidateSet(0, 1, 2)]
        [int] $Level = $(if (Test-IsRunningInPipeline) { 2 } else { 1 }),

        [ValidateSet('Minimal', 'Normal', 'Detailed', 'Diagnostic')]
        [string] $Output = 'Normal',

        [switch] $PassThru
    )

    # Lazy-load Pester — deferred at import time for speed
    if (-not (Get-Module Pester)) {
        $pesterPath = Join-Path $env:RepositoryRoot 'automation/.vendor/Pester'
        Write-Verbose "Lazy-loading Pester from: $pesterPath"
        Import-Module $pesterPath -Scope Global -Force
    }

    $automationRoot = Join-Path $env:RepositoryRoot 'automation'

    $testPaths = @(
        # Module tests
        Get-ChildItem -Path $automationRoot -Directory |
        Where-Object { $_.Name -notmatch '^\.' } |
        ForEach-Object { Join-Path $_.FullName 'tests' } |
        Where-Object { Test-Path $_ }

        # Infrastructure tests (.resolver, etc.)
        Get-ChildItem -Path $automationRoot -Directory |
        Where-Object { $_.Name -match '^\.' } |
        ForEach-Object { Join-Path $_.FullName 'tests' } |
        Where-Object { Test-Path $_ }
    )

    if (-not $testPaths) {
        throw 'No test folders found'
        return
    }

    # Build tag filter — exclude levels above the requested one
    $excludeTags = @()
    if ($Level -lt 2) { $excludeTags += 'L2' }
    if ($Level -lt 1) { $excludeTags += 'L1' }

    $config = New-PesterConfiguration
    $config.Run.Path = $testPaths
    $config.Run.PassThru = $true
    $config.Output.Verbosity = $Output
    if ($excludeTags.Count -gt 0) {
        $config.Filter.ExcludeTag = $excludeTags
    }

    $global:__PesterRunning = $true
    try {
        $result = Invoke-Pester -Configuration $config
    }
    finally {
        $global:__PesterRunning = $false
    }

    # Validate test durations against level limits
    # L0 < 400ms, L1 < 2s (default for untagged), L2 < 120s
    $limits = @{ 'L0' = 400; 'L1' = 2000; 'L2' = 120000 }
    $violations = @()

    foreach ($test in $result.Tests) {
        if ($test.Result -ne 'Passed') { continue }

        $tags = @($test.Block.Tag)
        $ms = [int]$test.Duration.TotalMilliseconds

        if ($tags -contains 'L0') {
            $limitMs = $limits['L0']
            $tag = 'L0'
        }
        elseif ($tags -contains 'L2') {
            $limitMs = $limits['L2']
            $tag = 'L2'
        }
        else {
            # Untagged or L1
            $limitMs = $limits['L1']
            $tag = 'L1'
        }

        if ($ms -gt $limitMs) {
            $violations += "[$tag > ${limitMs}ms] $($test.ExpandedName) took ${ms}ms"
        }
    }

    if ($violations.Count -gt 0) {
        Write-Information ''
        Write-InformationColored "Tests exceeding level time limits:" -ForegroundColor Red
        foreach ($v in $violations) {
            Write-InformationColored "  $v" -ForegroundColor Red
        }
        Write-Information "Tag slow tests with a higher level or optimize them."
        $result.Result = 'Failed'
    }

    if ($PassThru) {
        $result
    }
    elseif ($result.Result -ne 'Passed') {
        throw "Test-Automation failed: $($result.FailedCount) test(s) failed"
    }
}
