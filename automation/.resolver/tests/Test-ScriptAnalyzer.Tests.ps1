BeforeDiscovery {
    $automationRoot = Join-Path $env:RepositoryRoot 'automation'
    $settingsPath = Join-Path $env:RepositoryRoot 'PSScriptAnalyzerSettings.psd1'

    $allFiles = @()
    $modules = Get-ChildItem -Path $automationRoot -Directory |
        Where-Object { $_.Name -notmatch '^\.' }

    foreach ($moduleDir in $modules) {
        $publicFiles = Get-ChildItem -Path $moduleDir.FullName -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notlike '*.Tests.ps1' }
        foreach ($f in $publicFiles) {
            $allFiles += @{ Module = $moduleDir.Name; File = $f; Settings = $settingsPath }
        }

        $privatePath = Join-Path $moduleDir.FullName 'private'
        if (Test-Path $privatePath) {
            $privateFiles = Get-ChildItem -Path $privatePath -Filter '*.ps1' -File -ErrorAction SilentlyContinue
            foreach ($f in $privateFiles) {
                $allFiles += @{ Module = $moduleDir.Name; File = $f; Settings = $settingsPath }
            }
        }

        $testsPath = Join-Path $moduleDir.FullName 'tests'
        if (Test-Path $testsPath) {
            $testFiles = Get-ChildItem -Path $testsPath -Filter '*.Tests.ps1' -File -ErrorAction SilentlyContinue
            foreach ($f in $testFiles) {
                $allFiles += @{ Module = "$($moduleDir.Name)/tests"; File = $f; Settings = $settingsPath }
            }
        }
    }

    # Also include Resolver.psm1
    $resolver = Get-Item (Join-Path $automationRoot '.resolver/Resolver.psm1') -ErrorAction SilentlyContinue
    if ($resolver) {
        $allFiles += @{ Module = 'Resolver'; File = $resolver; Settings = $settingsPath }
    }
}

Describe 'PSScriptAnalyzer: <Module>/<File>' -Tag 'L2' -ForEach $allFiles {
    It 'has no PSScriptAnalyzer violations' {
        $diagnostics = Invoke-ScriptAnalyzer -Path $File.FullName -Settings $Settings
        $diagnostics | ForEach-Object {
            "$($_.RuleName): $($_.Message) (line $($_.Line))"
        } | Should -BeNullOrEmpty
    }
}
