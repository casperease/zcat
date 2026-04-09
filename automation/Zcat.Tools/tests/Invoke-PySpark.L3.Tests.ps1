Describe 'Invoke-PySpark' -Tag 'L3' {
    BeforeAll {
        $script:available = Test-Tool 'PySpark'
    }

    It 'outputs version info' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'PySpark not available'; return }
        $result = Invoke-PySpark '--version' -PassThru -Silent -NoAssert
        $result.Full | Should -Not -BeNullOrEmpty
    }
}
