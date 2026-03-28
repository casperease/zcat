Describe 'Install-Tool' {
    It 'is callable as a private function' {
        $cmd = & (Get-Module Zcap.Tools) { Get-Command Install-Tool -ErrorAction SilentlyContinue }
        $cmd | Should -Not -BeNullOrEmpty
    }

    It 'has mandatory Tool parameter' {
        $cmd = & (Get-Module Zcap.Tools) { Get-Command Install-Tool }
        $param = $cmd.Parameters['Tool']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
    }

    It 'has optional Version parameter' {
        $cmd = & (Get-Module Zcap.Tools) { Get-Command Install-Tool }
        $param = $cmd.Parameters['Version']
        $param | Should -Not -BeNullOrEmpty
        $param.ParameterType.Name | Should -Be 'String'
    }
}
