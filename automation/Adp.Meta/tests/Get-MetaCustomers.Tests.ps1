Describe 'Get-MetaCustomers' {
    BeforeAll {
        $script:customers = Get-MetaCustomers
    }

    It 'returns a non-empty array' {
        $customers | Should -Not -BeNullOrEmpty
    }

    It 'returns strings' {
        $customers | ForEach-Object { $_ | Should -BeOfType [string] }
    }

    It 'contains expected customers' {
        $customers | Should -Contain 'blue'
        $customers | Should -Contain 'bold'
    }

    It 'count matches meta.yml' {
        $config = Get-MetaConfiguration
        $customers | Should -HaveCount $config.customers.Count
    }
}
