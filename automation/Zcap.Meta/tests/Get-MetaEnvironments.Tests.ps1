Describe 'Get-MetaEnvironments' {
    BeforeAll {
        $script:envs = Get-MetaEnvironments
    }

    It 'returns a non-empty array' {
        $envs | Should -Not -BeNullOrEmpty
    }

    It 'returns strings' {
        $envs | ForEach-Object { $_ | Should -BeOfType [string] }
    }

    It 'contains dev, test, preprod, prod' {
        $envs | Should -Contain 'dev'
        $envs | Should -Contain 'test'
        $envs | Should -Contain 'preprod'
        $envs | Should -Contain 'prod'
    }
}
