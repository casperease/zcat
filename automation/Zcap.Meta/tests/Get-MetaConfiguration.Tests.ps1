Describe 'Get-MetaConfiguration' {
    Context 'asset dependencies' {
        It 'meta.yml exists' {
            Join-Path $PSScriptRoot '../assets/config/meta.yml' | Should -Exist
        }
    }

    Context 'behavior' {
        It 'returns a non-empty configuration' {
            $config = Get-MetaConfiguration
            $config | Should -Not -BeNullOrEmpty
        }

        It 'caches across calls' {
            $first = Get-MetaConfiguration
            $second = Get-MetaConfiguration
            [object]::ReferenceEquals($first, $second) | Should -BeTrue -Because 'repeated calls should return the same cached object'
        }
    }
}
