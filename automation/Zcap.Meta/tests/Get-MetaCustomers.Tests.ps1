Describe 'Get-MetaCustomers' {
    BeforeAll {
        $script:customers = Get-MetaCustomers
    }

    It 'contains expected customers' {
        $customers | Should -Contain 'apex'
        $customers | Should -Contain 'nova'
    }

    It 'count matches meta.yml' {
        $config = Get-MetaConfiguration
        $customers | Should -HaveCount $config.customers.Count
    }
}
