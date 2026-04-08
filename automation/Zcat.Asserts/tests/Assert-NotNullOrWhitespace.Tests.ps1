Describe 'Assert-NotNullOrWhitespace' {
    It 'passes when value is a non-empty string' {
        { Assert-NotNullOrWhitespace 'hello' } | Should -Not -Throw
    }

    It 'throws when value is $null' {
        { Assert-NotNullOrWhitespace $null } | Should -Throw
    }

    It 'throws when value is empty string' {
        { Assert-NotNullOrWhitespace '' } | Should -Throw
    }

    It 'throws when value is whitespace' {
        { Assert-NotNullOrWhitespace '   ' } | Should -Throw
    }

    It 'uses custom error text when provided' {
        { Assert-NotNullOrWhitespace '' -ErrorText 'custom message' } | Should -Throw -ExpectedMessage 'custom message'
    }
}
