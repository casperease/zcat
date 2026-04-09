Describe 'Invoke-Npm' -Tag 'L3' {
    BeforeAll {
        $script:available = Test-Tool 'NodeJs'
    }

    It 'prints npm root path' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'NodeJs not available'; return }
        $result = Invoke-Npm 'root' -PassThru -Silent
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'node_modules'
    }

    It 'returns config as JSON with accessible properties' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'NodeJs not available'; return }
        $result = Invoke-Npm 'config list --json' -PassThru -Silent
        $result.ExitCode | Should -Be 0
        $config = $result.Output | ConvertFrom-Json
        $config.prefix | Should -Not -BeNullOrEmpty
    }
}
