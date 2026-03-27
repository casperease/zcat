Describe 'Assert-Null' {
    It 'passes when value is $null' {
        { Assert-Null $null } | Should -Not -Throw
    }

    It 'throws when value is a string' {
        { Assert-Null 'hello' } | Should -Throw
    }

    It 'throws when value is a number' {
        { Assert-Null 0 } | Should -Throw
    }

    It 'uses custom error text when provided' {
        { Assert-Null 'x' -ErrorText 'custom message' } | Should -Throw -ExpectedMessage 'custom message'
    }
}
