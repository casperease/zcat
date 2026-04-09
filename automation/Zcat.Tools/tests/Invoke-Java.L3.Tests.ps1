Describe 'Invoke-Java' -Tag 'L3' {
    BeforeAll {
        $script:available = Test-Tool 'Java'
    }

    It 'outputs version info to stderr' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'Java not available'; return }
        $result = Invoke-Java '-version' -PassThru -Silent -NoAssert
        $result.Errors | Should -Match 'version'
    }
}
