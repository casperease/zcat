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

        It 'throws when SYSTEM_ACCESSTOKEN is missing in pipeline' {
            $origTfBuild = $env:TF_BUILD
            $origToken = $env:SYSTEM_ACCESSTOKEN
            try {
                $env:TF_BUILD = 'True'
                $env:SYSTEM_ACCESSTOKEN = $null

                { Get-AdoAuthorizationHeader } | Should -Throw '*No ADO token*'
            }
            finally {
                $env:TF_BUILD = $origTfBuild
                $env:SYSTEM_ACCESSTOKEN = $origToken
            }
        }
    }
}
