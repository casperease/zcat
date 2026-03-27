Describe 'Test-IsRunningInPipeline' {
    It 'returns a boolean' {
        Test-IsRunningInPipeline | Should -BeOfType [bool]
    }

    It 'detects Azure DevOps via TF_BUILD' {
        $original = $env:TF_BUILD
        try {
            $env:TF_BUILD = 'True'
            Test-IsRunningInPipeline | Should -BeTrue
        }
        finally {
            $env:TF_BUILD = $original
        }
    }

    It 'detects GitHub Actions via GITHUB_ACTIONS' {
        $original = $env:GITHUB_ACTIONS
        try {
            $env:GITHUB_ACTIONS = 'true'
            Test-IsRunningInPipeline | Should -BeTrue
        }
        finally {
            $env:GITHUB_ACTIONS = $original
        }
    }

    It 'returns false when no CI variables are set' {
        $origTf = $env:TF_BUILD
        $origGh = $env:GITHUB_ACTIONS
        try {
            $env:TF_BUILD = $null
            $env:GITHUB_ACTIONS = $null
            Test-IsRunningInPipeline | Should -BeFalse
        }
        finally {
            $env:TF_BUILD = $origTf
            $env:GITHUB_ACTIONS = $origGh
        }
    }
}
