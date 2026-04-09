Describe 'Invoke-Poetry' -Tag 'L3' {
    BeforeAll {
        $script:available = Test-Tool 'Poetry'
    }

    It 'lists poetry configuration' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'Poetry not available'; return }
        $result = Invoke-Poetry 'config --list' -PassThru -Silent
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'virtualenvs'
    }
}
