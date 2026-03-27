Describe 'Get-MetaConfiguration' {
    BeforeAll {
        $script:config = Get-MetaConfiguration
    }

    It 'returns a result' {
        $config | Should -Not -BeNullOrEmpty
    }

    It 'returns an ordered dictionary' {
        $config | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
    }

    It 'contains subscription_types' {
        $config.Contains('subscription_types') | Should -BeTrue
    }

    It 'contains environments' {
        $config.Contains('environments') | Should -BeTrue
    }

    It 'contains environment_types' {
        $config.Contains('environment_types') | Should -BeTrue
    }

    It 'contains environment_subtypes' {
        $config.Contains('environment_subtypes') | Should -BeTrue
    }

    It 'contains customers' {
        $config.Contains('customers') | Should -BeTrue
    }
}
