Describe 'Test-IsGuid' {
    It 'returns $true for a valid GUID' {
        Test-IsGuid '550e8400-e29b-41d4-a716-446655440000' | Should -BeTrue
    }

    It 'returns $true for a GUID with braces' {
        Test-IsGuid '{550e8400-e29b-41d4-a716-446655440000}' | Should -BeTrue
    }

    It 'returns $false for an invalid string' {
        Test-IsGuid 'not-a-guid' | Should -BeFalse
    }

    It 'rejects an empty string' {
        { Test-IsGuid '' } | Should -Throw
    }
}
