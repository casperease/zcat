Describe 'Uninstall-Python' {
    It 'is exported and callable' {
        Get-Command Uninstall-Python | Should -Not -BeNullOrEmpty
    }

    It 'has optional Version parameter' {
        $param = (Get-Command Uninstall-Python).Parameters['Version']
        $param | Should -Not -BeNullOrEmpty
        $param.ParameterType.Name | Should -Be 'String'
    }
}
