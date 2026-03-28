Describe 'Get-MetaEnvironments' {
    BeforeAll {
        $script:envs = Get-MetaEnvironments
    }

    It 'contains dev, test, preprod, prod' {
        $envs | Should -Contain 'dev'
        $envs | Should -Contain 'test'
        $envs | Should -Contain 'preprod'
        $envs | Should -Contain 'prod'
    }
}
