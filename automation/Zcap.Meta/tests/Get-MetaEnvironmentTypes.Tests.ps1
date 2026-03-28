Describe 'Get-MetaEnvironmentTypes' {
    It 'returns all types by default' {
        $all = Get-MetaEnvironmentTypes
        $all | Should -Not -BeNullOrEmpty
    }

    It '-Scope Customer returns only customer types' {
        $customer = Get-MetaEnvironmentTypes -Scope Customer
        $customer | Should -Not -BeNullOrEmpty
        $customer | Should -Contain 'core_customer'
    }

    It '-Scope Shared returns only shared types' {
        $shared = Get-MetaEnvironmentTypes -Scope Shared
        $shared | Should -Not -BeNullOrEmpty
        $shared | Should -Contain 'orthog'
    }

    It 'All count equals Customer + Shared count' {
        $all = Get-MetaEnvironmentTypes
        $customer = Get-MetaEnvironmentTypes -Scope Customer
        $shared = Get-MetaEnvironmentTypes -Scope Shared
        $all | Should -HaveCount ($customer.Count + $shared.Count)
    }

    It 'Customer and Shared have no overlap' {
        $customer = Get-MetaEnvironmentTypes -Scope Customer
        $shared = Get-MetaEnvironmentTypes -Scope Shared
        $overlap = $customer | Where-Object { $_ -in $shared }
        $overlap | Should -BeNullOrEmpty
    }
}
