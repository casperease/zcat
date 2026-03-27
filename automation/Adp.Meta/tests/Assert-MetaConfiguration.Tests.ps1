Describe 'Assert-MetaConfiguration' {
    BeforeAll {
        $script:baseConfig = [ordered]@{
            subscription_types   = @('prod', 'nonprod')
            environments         = [ordered]@{
                dev  = [ordered]@{ details = 'Development'; subscription_type = 'nonprod' }
                prod = [ordered]@{ details = 'Production'; subscription_type = 'prod' }
            }
            environment_subtypes = @('sub')
            environment_types    = [ordered]@{
                customer = [ordered]@{
                    core = [ordered]@{ subtypes = @() }
                }
                shared = [ordered]@{
                    orthog = [ordered]@{ subtypes = @() }
                }
            }
            customers = [ordered]@{
                blue = [ordered]@{
                    details           = 'test customer'
                    environment_types = @('core')
                }
            }
        }
    }

    It 'passes for current meta.yml' {
        $config = Get-MetaConfiguration
        { & (Get-Module Adp.Meta) { Assert-MetaConfiguration $args[0] } $config } | Should -Not -Throw
    }

    It 'passes for minimal valid config' {
        { & (Get-Module Adp.Meta) { Assert-MetaConfiguration $args[0] } (Copy-Object $baseConfig) } | Should -Not -Throw
    }

    It 'throws when missing required top-level key' {
        $bad = [ordered]@{ subscription_types = @('prod') }
        { & (Get-Module Adp.Meta) { Assert-MetaConfiguration $args[0] } $bad } | Should -Throw '*Missing required*'
    }

    It 'throws when customer references unknown environment_type' {
        $bad = Copy-Object $baseConfig
        $bad.customers = [ordered]@{
            bad = [ordered]@{ details = 'bad'; environment_types = @('nonexistent') }
        }
        { & (Get-Module Adp.Meta) { Assert-MetaConfiguration $args[0] } $bad } | Should -Throw '*unknown environment_type*'
    }

    It 'throws for duplicate subscription_types' {
        $bad = Copy-Object $baseConfig
        $bad.subscription_types = @('prod', 'prod')
        { & (Get-Module Adp.Meta) { Assert-MetaConfiguration $args[0] } $bad } | Should -Throw '*Duplicate subscription_type*'
    }

    It 'throws when environment_type appears in both customer and shared' {
        $bad = Copy-Object $baseConfig
        $bad.environment_types = [ordered]@{
            customer = [ordered]@{ overlap = [ordered]@{ subtypes = @() } }
            shared   = [ordered]@{ overlap = [ordered]@{ subtypes = @() } }
        }
        $bad.customers = [ordered]@{
            test = [ordered]@{ details = 'x'; environment_types = @('overlap') }
        }
        { & (Get-Module Adp.Meta) { Assert-MetaConfiguration $args[0] } $bad } | Should -Throw '*both customer and shared*'
    }

    It 'throws when environment has invalid subscription_type' {
        $bad = Copy-Object $baseConfig
        $bad.environments = [ordered]@{
            dev = [ordered]@{ details = 'Dev'; subscription_type = 'invalid' }
        }
        { & (Get-Module Adp.Meta) { Assert-MetaConfiguration $args[0] } $bad } | Should -Throw '*invalid subscription_type*'
    }
}
