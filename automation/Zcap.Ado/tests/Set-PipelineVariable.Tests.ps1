Describe 'Set-PipelineVariable' {
    Context 'name sanitization' {
        BeforeAll {
            $origTfBuild = $env:TF_BUILD
            $env:TF_BUILD = 'True'
        }
        AfterAll {
            $env:TF_BUILD = $origTfBuild
        }

        It 'replaces dots with underscores' {
            $output = Set-PipelineVariable -Name 'dev.capi' -Value 'Deploy' 6>&1 4>&1 *>&1
            $vsoLine = $output | Where-Object { $_ -match '##vso' }
            $vsoLine | Should -Match 'variable=dev_capi'
        }

        It 'replaces hyphens with underscores' {
            $output = Set-PipelineVariable -Name 'my-var' -Value 'x' 6>&1 4>&1 *>&1
            $vsoLine = $output | Where-Object { $_ -match '##vso' }
            $vsoLine | Should -Match 'variable=my_var'
        }

        It 'removes apostrophes' {
            $output = Set-PipelineVariable -Name "it's" -Value 'x' 6>&1 4>&1 *>&1
            $vsoLine = $output | Where-Object { $_ -match '##vso' }
            $vsoLine | Should -Match 'variable=its'
        }
    }

    Context 'flags' {
        BeforeAll {
            $origTfBuild = $env:TF_BUILD
            $env:TF_BUILD = 'True'
        }
        AfterAll {
            $env:TF_BUILD = $origTfBuild
        }

        It 'includes isOutput when -IsOutput is set' {
            $output = Set-PipelineVariable -Name 'Foo' -Value 'bar' -IsOutput 6>&1 4>&1 *>&1
            $vsoLine = $output | Where-Object { $_ -match '##vso' }
            $vsoLine | Should -Match 'isOutput=true'
        }

        It 'sets issecret=true when -IsSecret is set' {
            $output = Set-PipelineVariable -Name 'Foo' -Value 'secret' -IsSecret 6>&1 4>&1 *>&1
            $vsoLine = $output | Where-Object { $_ -match '##vso' }
            $vsoLine | Should -Match 'issecret=true'
        }

        It 'sets issecret=false by default' {
            $output = Set-PipelineVariable -Name 'Foo' -Value 'bar' 6>&1 4>&1 *>&1
            $vsoLine = $output | Where-Object { $_ -match '##vso' }
            $vsoLine | Should -Match 'issecret=false'
        }
    }

    Context 'outside pipeline' {
        BeforeAll {
            $origTfBuild = $env:TF_BUILD
            $origGhActions = $env:GITHUB_ACTIONS
            $env:TF_BUILD = $null
            $env:GITHUB_ACTIONS = $null
        }
        AfterAll {
            $env:TF_BUILD = $origTfBuild
            $env:GITHUB_ACTIONS = $origGhActions
        }

        It 'does not emit ##vso command when not in pipeline' {
            $output = Set-PipelineVariable -Name 'Foo' -Value 'bar' -Verbose 4>&1 *>&1
            $vsoLine = $output | Where-Object { $_ -match '^\#\#vso\[' }
            $vsoLine | Should -BeNullOrEmpty
        }
    }

    Context 'validation' {
        It 'throws on empty name' {
            { Set-PipelineVariable -Name '  ' -Value 'x' } | Should -Throw
        }

        It 'allows empty value' {
            $origTfBuild = $env:TF_BUILD
            try {
                $env:TF_BUILD = 'True'
                { Set-PipelineVariable -Name 'Foo' -Value '' 6>&1 *>&1 | Out-Null } | Should -Not -Throw
            }
            finally {
                $env:TF_BUILD = $origTfBuild
            }
        }
    }
}
