BeforeDiscovery {
    $automationRoot = Join-Path $env:RepositoryRoot 'automation'
    $settingsPath = Join-Path $env:RepositoryRoot 'PSScriptAnalyzerSettings.psd1'

    # Discover module directories (excludes dot-prefixed: .vendor, .scriptanalyzer, .resolver)
    $modules = Get-ChildItem -Path $automationRoot -Directory |
        Where-Object { $_.Name -notmatch '^\.' }

    # Run PSScriptAnalyzer on module code only (root, private/, tests/).
    # assets/ is excluded — it contains vendored or external files we do not control.
    # Parallel is not possible (PSScriptAnalyzer Helper.Initialize is not thread-safe).
    $allDiagnostics = @()
    foreach ($moduleDir in $modules) {
        # Module root (public functions)
        $allDiagnostics += Invoke-ScriptAnalyzer -Path $moduleDir.FullName -Settings $settingsPath
        # Private helpers
        $privatePath = Join-Path $moduleDir.FullName 'private'
        if (Test-Path $privatePath) {
            $allDiagnostics += Invoke-ScriptAnalyzer -Path $privatePath -Settings $settingsPath
        }
        # Test files
        $testsPath = Join-Path $moduleDir.FullName 'tests'
        if (Test-Path $testsPath) {
            $allDiagnostics += Invoke-ScriptAnalyzer -Path $testsPath -Settings $settingsPath
        }
    }

    $resolverPath = Join-Path $automationRoot '.resolver/Resolver.psm1'
    if (Test-Path $resolverPath) {
        $allDiagnostics += Invoke-ScriptAnalyzer -Path $resolverPath -Settings $settingsPath
    }

    # Index diagnostics as strings by file path.
    # DiagnosticRecord objects don't survive Pester's -ForEach serialization,
    # so convert to readable strings during discovery.
    $diagnosticsByFile = @{}
    foreach ($d in $allDiagnostics) {
        if (-not $diagnosticsByFile.ContainsKey($d.ScriptPath)) {
            $diagnosticsByFile[$d.ScriptPath] = [System.Collections.Generic.List[string]]::new()
        }
        $diagnosticsByFile[$d.ScriptPath].Add("$($d.RuleName): $($d.Message) (line $($d.Line))")
    }

    # Build per-file test cases
    $allFiles = @()
    foreach ($moduleDir in $modules) {
        $publicFiles = Get-ChildItem -Path $moduleDir.FullName -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notlike '*.Tests.ps1' }
        foreach ($f in $publicFiles) {
            $allFiles += @{ Module = $moduleDir.Name; File = $f; Diagnostics = $diagnosticsByFile[$f.FullName] }
        }

        $privatePath = Join-Path $moduleDir.FullName 'private'
        if (Test-Path $privatePath) {
            $privateFiles = Get-ChildItem -Path $privatePath -Filter '*.ps1' -File -ErrorAction SilentlyContinue
            foreach ($f in $privateFiles) {
                $allFiles += @{ Module = $moduleDir.Name; File = $f; Diagnostics = $diagnosticsByFile[$f.FullName] }
            }
        }

        $testsPath = Join-Path $moduleDir.FullName 'tests'
        if (Test-Path $testsPath) {
            $testFiles = Get-ChildItem -Path $testsPath -Filter '*.Tests.ps1' -File -ErrorAction SilentlyContinue
            foreach ($f in $testFiles) {
                $allFiles += @{ Module = "$($moduleDir.Name)/tests"; File = $f; Diagnostics = $diagnosticsByFile[$f.FullName] }
            }
        }
    }

    $resolver = Get-Item (Join-Path $automationRoot '.resolver/Resolver.psm1') -ErrorAction SilentlyContinue
    if ($resolver) {
        $allFiles += @{ Module = 'Resolver'; File = $resolver; Diagnostics = $diagnosticsByFile[$resolver.FullName] }
    }
}

Describe 'PSScriptAnalyzer: <Module>/<File>' -Tag 'L2' -ForEach $allFiles {
    It 'has no PSScriptAnalyzer violations' {
        $Diagnostics | Should -BeNullOrEmpty
    }
}
