Describe 'Test-NotNullOrWhitespace' {
    It 'returns $true for non-empty string' {
        Test-NotNullOrWhitespace 'hello' | Should -BeTrue
    }

    It 'returns $false for $null' {
        Test-NotNullOrWhitespace $null | Should -BeFalse
    }

    It 'returns $false for empty string' {
        Test-NotNullOrWhitespace '' | Should -BeFalse
    }

    It 'returns $false for whitespace' {
        Test-NotNullOrWhitespace '   ' | Should -BeFalse
    }
}
