Describe 'Assert-True' {
    It 'passes when value is $true' {
        { Assert-True $true } | Should -Not -Throw
    }

    It 'throws when value is $false' {
        { Assert-True $false } | Should -Throw
    }

    It 'throws when value is not a boolean' {
        { Assert-True 1 } | Should -Throw
    }

    It 'throws when value is $null' {
        { Assert-True $null } | Should -Throw
    }

    It 'uses custom error text when provided' {
        { Assert-True $false -ErrorText 'custom message' } | Should -Throw -ExpectedMessage 'custom message'
    }
}
