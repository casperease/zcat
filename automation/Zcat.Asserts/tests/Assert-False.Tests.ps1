Describe 'Assert-False' {
    It 'passes when value is $false' {
        { Assert-False $false } | Should -Not -Throw
    }

    It 'throws when value is $true' {
        { Assert-False $true } | Should -Throw
    }

    It 'throws when value is not a boolean' {
        { Assert-False 0 } | Should -Throw
    }

    It 'throws when value is $null' {
        { Assert-False $null } | Should -Throw
    }

    It 'uses custom error text when provided' {
        { Assert-False $true -ErrorText 'custom message' } | Should -Throw -ExpectedMessage 'custom message'
    }
}
