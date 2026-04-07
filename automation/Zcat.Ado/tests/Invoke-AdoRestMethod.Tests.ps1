Describe 'Invoke-AdoRestMethod' {
    Context 'parameter validation' {
        It 'requires Uri parameter' {
            { Invoke-AdoRestMethod -Uri $null } | Should -Throw
        }

        It 'validates Method values' {
            { Invoke-AdoRestMethod -Uri 'https://example.com' -Method 'INVALID' } | Should -Throw
        }
    }
}
