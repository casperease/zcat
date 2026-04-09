Describe 'Invoke-Dotnet' -Tag 'L3' {
    BeforeAll {
        $script:available = Test-Tool 'Dotnet'
    }

    It 'lists installed SDKs as multi-line output' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'Dotnet not available'; return }
        $result = Invoke-Dotnet '--list-sdks' -PassThru -Silent
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Not -BeNullOrEmpty
        $result.Raw.Count | Should -BeGreaterOrEqual 1
    }
}
