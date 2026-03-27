Describe 'Uninstall-AzCli' {
    It 'is exported and callable' {
        Get-Command Uninstall-AzCli | Should -Not -BeNullOrEmpty
    }

    It 'has optional Version parameter' {
        $param = (Get-Command Uninstall-AzCli).Parameters['Version']
        $param | Should -Not -BeNullOrEmpty
        $param.ParameterType.Name | Should -Be 'String'
    }
}
