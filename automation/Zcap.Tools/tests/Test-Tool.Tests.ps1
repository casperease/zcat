Describe 'Test-Tool' {
    It 'is callable as a private function' {
        $cmd = & (Get-Module Zcap.Tools) { Get-Command Test-Tool -ErrorAction SilentlyContinue }
        $cmd | Should -Not -BeNullOrEmpty
    }

    It 'has mandatory Tool parameter' {
        $cmd = & (Get-Module Zcap.Tools) { Get-Command Test-Tool }
        $param = $cmd.Parameters['Tool']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
    }

    It 'returns bool' {
        $cmd = & (Get-Module Zcap.Tools) { Get-Command Test-Tool }
        $cmd.OutputType.Type | Should -Contain ([bool])
    }
}
