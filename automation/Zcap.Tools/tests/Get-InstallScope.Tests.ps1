Describe 'Get-InstallScope' {
    It 'is callable as a private function' {
        $cmd = & (Get-Module Zcap.Tools) { Get-Command Get-InstallScope -ErrorAction SilentlyContinue }
        $cmd | Should -Not -BeNullOrEmpty
    }

    It 'has mandatory Config parameter' {
        $cmd = & (Get-Module Zcap.Tools) { Get-Command Get-InstallScope }
        $param = $cmd.Parameters['Config']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
    }

    It 'has mandatory Location parameter' {
        $cmd = & (Get-Module Zcap.Tools) { Get-Command Get-InstallScope }
        $param = $cmd.Parameters['Location']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
    }
}
