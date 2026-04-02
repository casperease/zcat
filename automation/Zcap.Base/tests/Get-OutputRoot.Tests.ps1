Describe 'Get-OutputRoot' {
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

        It 'returns out/ under repository root' {
            $result = Get-OutputRoot
            $expected = Join-Path (Get-RepositoryRoot) 'out'
            $result | Should -Be $expected
        }
    }

    Context 'in pipeline' {
        It 'returns BUILD_ARTIFACTSTAGINGDIRECTORY when set' {
            $origTfBuild = $env:TF_BUILD
            $origArtifacts = $env:BUILD_ARTIFACTSTAGINGDIRECTORY
            try {
                $env:TF_BUILD = 'True'
                # Use an existing directory for the assertion inside the function
                $env:BUILD_ARTIFACTSTAGINGDIRECTORY = $TestDrive

                $result = Get-OutputRoot
                $result | Should -Be $TestDrive
            }
            finally {
                $env:TF_BUILD = $origTfBuild
                $env:BUILD_ARTIFACTSTAGINGDIRECTORY = $origArtifacts
            }
        }
    }

    Context 'EnsureExists' {
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

        It 'creates directory when it does not exist' {
            $result = Get-OutputRoot -EnsureExists
            $result | Should -Exist
        }
    }
}
