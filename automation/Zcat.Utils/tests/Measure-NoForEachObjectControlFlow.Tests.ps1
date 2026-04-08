BeforeAll {
    $rulePath = Join-Path $PSScriptRoot '..\..' '.scriptanalyzer' 'NoForEachObjectControlFlow.psm1' | Resolve-Path
    Import-Module $rulePath -Force
    # Empty settings prevents PSSA from auto-discovering PSScriptAnalyzerSettings.psd1
    # (which already lists this rule in CustomRulePath, causing double invocation).
    $emptySettings = @{ IncludeRules = @('Measure-NoForEachObjectControlFlow') }
}

Describe 'Measure-NoForEachObjectControlFlow' {

    # ── Should flag ─────────────────────────────────────────────

    It 'flags return inside ForEach-Object' {
        $script = @'
            $items | ForEach-Object {
                if ($_.Bad) { return }
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -HaveCount 1
        $results[0].RuleName | Should -Be 'Measure-NoForEachObjectControlFlow'
        $results[0].Message | Should -Match 'return'
    }

    It 'flags break inside ForEach-Object' {
        $script = @'
            $items | ForEach-Object {
                if ($_.Done) { break }
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -HaveCount 1
        $results[0].Message | Should -Match 'break'
    }

    It 'flags continue inside ForEach-Object' {
        $script = @'
            $items | ForEach-Object {
                if ($_.Skip) { continue }
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -HaveCount 1
        $results[0].Message | Should -Match 'continue'
    }

    It 'flags all three keywords in one scriptblock' {
        $script = @'
            $items | ForEach-Object {
                if ($_.A) { return }
                if ($_.B) { break }
                if ($_.C) { continue }
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -HaveCount 3
    }

    It 'flags the % alias the same as ForEach-Object' {
        $script = @'
            $items | % {
                if ($_.Bad) { return }
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -HaveCount 1
    }

    It 'flags return inside ForEach-Object even when nested in if/else' {
        $script = @'
            $items | ForEach-Object {
                if ($_.Type -eq 'A') {
                    return 'found'
                }
                else {
                    return 'default'
                }
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -HaveCount 2
    }

    It 'flags break inside ForEach-Object with no enclosing loop (script-terminating)' {
        $script = @'
            1..10 | ForEach-Object {
                if ($_ -eq 5) { break }
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -HaveCount 1
    }

    It 'has Error severity' {
        $script = @'
            $items | ForEach-Object { return }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results[0].Severity | Should -Be 'Error'
    }

    # ── Should not flag ─────────────────────────────────────────

    It 'allows simple expressions without control flow' {
        $script = @'
            $items | ForEach-Object { $_.Name }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows return inside a foreach inside ForEach-Object' {
        $script = @'
            $batches | ForEach-Object {
                foreach ($item in $_.Items) {
                    if ($item.Done) { return }
                }
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows break inside a for loop inside ForEach-Object' {
        $script = @'
            $items | ForEach-Object {
                for ($i = 0; $i -lt 10; $i++) {
                    if ($i -eq 5) { break }
                }
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows continue inside a while loop inside ForEach-Object' {
        $script = @'
            $items | ForEach-Object {
                $i = 0
                while ($i -lt 10) {
                    $i++
                    if ($i -eq 3) { continue }
                }
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows break inside a switch inside ForEach-Object' {
        $script = @'
            $items | ForEach-Object {
                switch ($_.Type) {
                    'A' { 'alpha'; break }
                    'B' { 'beta'; break }
                }
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows return inside a nested function inside ForEach-Object' {
        $script = @'
            $items | ForEach-Object {
                function Get-Thing { return 'value' }
                Get-Thing
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows return inside a nested scriptblock inside ForEach-Object' {
        $script = @'
            $items | ForEach-Object {
                $action = { return 'done' }
                & $action
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'does not flag foreach statement (only ForEach-Object cmdlet)' {
        $script = @'
            foreach ($item in $items) {
                if ($item.Done) { return }
                if ($item.Skip) { continue }
                if ($item.Last) { break }
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'does not flag Where-Object with return' {
        $script = @'
            $items | Where-Object { return $_.Enabled }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }
}
