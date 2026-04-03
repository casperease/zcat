Describe 'Set-AdoPipelineVariable' {
    Context 'name validation' {
        It 'throws on dots in name' {
            { Set-AdoPipelineVariable -Name 'dev.capi' -Value 'x' } | Should -Throw '*silently replaces*'
        }

        It 'throws on hyphens in name' {
            { Set-AdoPipelineVariable -Name 'my-var' -Value 'x' } | Should -Throw '*silently replaces*'
        }

        It 'throws on apostrophes in name' {
            { Set-AdoPipelineVariable -Name "it's" -Value 'x' } | Should -Throw '*silently replaces*'
        }

        It 'throws on empty name' {
            { Set-AdoPipelineVariable -Name '  ' -Value 'x' } | Should -Throw
        }

        It 'accepts clean names' {
            $origTfBuild = $env:TF_BUILD
            try {
                $env:TF_BUILD = 'True'
                { Set-AdoPipelineVariable -Name 'dev_capi' -Value 'Deploy' 6>&1 *>&1 | Out-Null } | Should -Not -Throw
            }
            finally {
                $env:TF_BUILD = $origTfBuild
            }
        }
    }

    Context 'SanitizeName' {
        BeforeAll {
            $origTfBuild = $env:TF_BUILD
            $env:TF_BUILD = 'True'
        }
        AfterAll {
            $env:TF_BUILD = $origTfBuild
        }

        It 'replaces dots with underscores when -SanitizeName' {
            $output = Set-AdoPipelineVariable -Name 'dev.capi' -Value 'Deploy' -SanitizeName 6>&1 4>&1 *>&1
            $vsoLine = $output | Where-Object { $_ -match '##vso' }
            $vsoLine | Should -Match 'variable=dev_capi'
        }

        It 'replaces hyphens with underscores when -SanitizeName' {
            $output = Set-AdoPipelineVariable -Name 'my-var' -Value 'x' -SanitizeName 6>&1 4>&1 *>&1
            $vsoLine = $output | Where-Object { $_ -match '##vso' }
            $vsoLine | Should -Match 'variable=my_var'
        }

        It 'removes apostrophes when -SanitizeName' {
            $output = Set-AdoPipelineVariable -Name "it's" -Value 'x' -SanitizeName 6>&1 4>&1 *>&1
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
            $output = Set-AdoPipelineVariable -Name 'Foo' -Value 'bar' -IsOutput 6>&1 4>&1 *>&1
            $vsoLine = $output | Where-Object { $_ -match '##vso' }
            $vsoLine | Should -Match 'isOutput=true'
        }

        It 'sets issecret=true when -IsSecret is set' {
            $output = Set-AdoPipelineVariable -Name 'Foo' -Value 'secret' -IsSecret 6>&1 4>&1 *>&1
            $vsoLine = $output | Where-Object { $_ -match '##vso' }
            $vsoLine | Should -Match 'issecret=true'
        }

        It 'sets issecret=false by default' {
            $output = Set-AdoPipelineVariable -Name 'Foo' -Value 'bar' 6>&1 4>&1 *>&1
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
            $output = Set-AdoPipelineVariable -Name 'Foo' -Value 'bar' -Verbose 4>&1 *>&1
            $vsoLine = $output | Where-Object { $_ -match '^\#\#vso\[' }
            $vsoLine | Should -BeNullOrEmpty
        }
    }

    Context 'validation' {
        It 'allows empty value' {
            $origTfBuild = $env:TF_BUILD
            try {
                $env:TF_BUILD = 'True'
                { Set-AdoPipelineVariable -Name 'Foo' -Value '' 6>&1 *>&1 | Out-Null } | Should -Not -Throw
            }
            finally {
                $env:TF_BUILD = $origTfBuild
            }
        }
    }
}
