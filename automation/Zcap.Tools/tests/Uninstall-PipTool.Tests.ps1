Describe 'Uninstall-PipTool' {
    It 'is callable as a private function' {
        $cmd = & (Get-Module Zcap.Tools) { Get-Command Uninstall-PipTool -ErrorAction SilentlyContinue }
        $cmd | Should -Not -BeNullOrEmpty
    }

    It 'has mandatory Tool parameter' {
        $cmd = & (Get-Module Zcap.Tools) { Get-Command Uninstall-PipTool }
        $param = $cmd.Parameters['Tool']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
    }
}
