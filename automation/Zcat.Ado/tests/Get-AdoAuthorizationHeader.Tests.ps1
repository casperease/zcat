Describe 'Get-AdoAuthorizationHeader' {
    Context 'in pipeline' {
        It 'uses SYSTEM_ACCESSTOKEN when in pipeline' {
            $origTfBuild = $env:TF_BUILD
            $origToken = $env:SYSTEM_ACCESSTOKEN
            try {
                $env:TF_BUILD = 'True'
                $env:SYSTEM_ACCESSTOKEN = 'test-token-value'

                $header = Get-AdoAuthorizationHeader
                $header | Should -BeOfType [hashtable]
                $header.Authorization | Should -Be 'Bearer test-token-value'
            }
            finally {
                $env:TF_BUILD = $origTfBuild
                $env:SYSTEM_ACCESSTOKEN = $origToken
            }
        }
    }

    Context 'PAT authentication' {
        It 'uses AZURE_DEVOPS_PAT with Basic auth' {
            $origTfBuild = $env:TF_BUILD
            $origToken = $env:SYSTEM_ACCESSTOKEN
            $origPat = $env:AZURE_DEVOPS_PAT
            try {
                $env:TF_BUILD = $null
                $env:SYSTEM_ACCESSTOKEN = $null
                $env:AZURE_DEVOPS_PAT = 'test-pat-value'

                $header = Get-AdoAuthorizationHeader
                $header | Should -BeOfType [hashtable]
                $expected = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(':test-pat-value'))
                $header.Authorization | Should -Be "Basic $expected"
            }
            finally {
                $env:TF_BUILD = $origTfBuild
                $env:SYSTEM_ACCESSTOKEN = $origToken
                $env:AZURE_DEVOPS_PAT = $origPat
            }
        }
    }
}
