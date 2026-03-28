Describe 'Get-ScriptInstallDir' {
    It 'is callable as a private function' {
        $cmd = & (Get-Module Zcap.Tools) { Get-Command Get-ScriptInstallDir -ErrorAction SilentlyContinue }
        $cmd | Should -Not -BeNullOrEmpty
    }

    It 'has mandatory Config parameter' {
        $cmd = & (Get-Module Zcap.Tools) { Get-Command Get-ScriptInstallDir }
        $param = $cmd.Parameters['Config']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
    }
}
