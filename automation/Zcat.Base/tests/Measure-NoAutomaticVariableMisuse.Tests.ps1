BeforeAll {
    $rulePath = Join-Path $PSScriptRoot '..\..' '.scriptanalyzer' 'NoAutomaticVariableMisuse.psm1' | Resolve-Path
    Import-Module $rulePath -Force
    # Empty settings prevents PSSA from auto-discovering PSScriptAnalyzerSettings.psd1
    # (which already lists this rule in CustomRulePath, causing double invocation).
    $emptySettings = @{ IncludeRules = @('Measure-NoAutomaticVariableMisuse') }
}

Describe 'Measure-NoAutomaticVariableMisuse' {

    # ── Should flag ─────────────────────────────────────────────

    It 'flags $? in an if condition' {
        $script = @'
            Get-Item 'C:\test'
            if (-not $?) { throw 'failed' }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -HaveCount 1
        $results[0].RuleName | Should -Be 'Measure-NoAutomaticVariableMisuse'
        $results[0].Message | Should -Match '\$\?'
    }

    It 'flags $? assigned to a variable' {
        $script = @'
            Get-Item 'C:\test'
            $ok = $?
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -HaveCount 1
    }

    It 'flags multiple $? usages' {
        $script = @'
            Do-Thing
            $a = $?
            Do-Other
            $b = $?
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -HaveCount 2
    }

    It 'has Error severity' {
        $script = @'
            $x = $?
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results[0].Severity | Should -Be 'Error'
    }

    # ── Should not flag ─────────────────────────────────────────

    It 'does not flag $LASTEXITCODE' {
        $script = @'
            git status
            if ($LASTEXITCODE -ne 0) { throw 'git failed' }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'does not flag other automatic variables' {
        $script = @'
            $_ | Write-Output
            $PSScriptRoot
            $PSVersionTable
            $true
            $null
            $Error
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }

    It 'does not flag regular variables' {
        $script = @'
            $result = Get-Item 'C:\test'
            if (-not $result) { throw 'failed' }
'@
        $results = Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath $rulePath -Settings $emptySettings
        $results | Should -BeNullOrEmpty
    }
}
