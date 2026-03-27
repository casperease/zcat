Describe 'Install-Python' {
    It 'is exported and callable' {
        Get-Command Install-Python | Should -Not -BeNullOrEmpty
    }

    It 'has optional Version parameter' {
        $param = (Get-Command Install-Python).Parameters['Version']
        $param | Should -Not -BeNullOrEmpty
        $param.ParameterType.Name | Should -Be 'String'
    }
}
