BeforeAll {
    $rulePath = Join-Path $PSScriptRoot '..\..' '.scriptanalyzer' 'NoSemicolons.psm1' | Resolve-Path
    Import-Module $rulePath -Force
    $emptySettings = @{ IncludeRules = @('Measure-NoSemicolons') }
}

Describe 'Measure-NoSemicolons' {

    # ── Should flag ─────────────────────────────────────────────

    It 'flags trailing semicolon' {
        $script = @'
            $x = 1;
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -HaveCount 1
        $results[0].RuleName | Should -Be 'Measure-NoSemicolons'
        $results[0].Severity | Should -Be 'Error'
    }

    It 'allows inline semicolon chaining two statements on one line' {
        $script = @'
            $a = 1; $b = 2
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows multiple semicolons chaining on one line' {
        $script = @'
            $a = 1; $b = 2; $c = 3
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows semicolons inside braces on one line' {
        $script = @'
            if ($true) { $a = 1; $b = 2 }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows semicolons in a while loop body on one line' {
        $script = @'
            while ($true) { Do-A; Do-B }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    # ── Should not flag ─────────────────────────────────────────

    It 'allows semicolons in for loop headers' {
        $script = @'
            for ($i = 0; $i -lt 10; $i++) {
                $i
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows for loop with complex expressions in header' {
        $script = @'
            for ($i = $start; $i -le $end; $i += $step) {
                Process-Item $i
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'does not flag semicolons inside strings' {
        $script = @'
            $path = "C:\bin;C:\tools"
            $items = $path -split ';'
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'does not flag clean code without semicolons' {
        $script = @'
            $a = 1
            $b = 2
            $c = $a + $b
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows semicolons in inline hash table literals' {
        $script = @'
            $obj = @{ Name = 'test'; Value = 42 }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows semicolons in ordered hash table literals' {
        $script = @'
            $obj = [ordered]@{ z = 1; a = 2; m = 3 }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows semicolons in nested hash table literals' {
        $script = @'
            $obj = @{ b = @{ z = 1; a = 2 }; a = 'leaf' }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows semicolons in PSCustomObject hash table' {
        $script = @'
            $obj = [PSCustomObject]@{ Name = 'test'; Value = 42 }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'allows semicolons in for loop body on one line' {
        $script = @'
            for ($i = 0; $i -lt 10; $i++) {
                Do-A; Do-B
            }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }
}
