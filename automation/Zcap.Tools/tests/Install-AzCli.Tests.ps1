Describe 'Install-AzCli' {
    It 'is exported and callable' {
        Get-Command Install-AzCli | Should -Not -BeNullOrEmpty
    }

    It 'has optional Version parameter' {
        $param = (Get-Command Install-AzCli).Parameters['Version']
        $param | Should -Not -BeNullOrEmpty
        $param.ParameterType.Name | Should -Be 'String'
    }

    It 'has Force switch parameter' {
        $param = (Get-Command Install-AzCli).Parameters['Force']
        $param | Should -Not -BeNullOrEmpty
        $param.ParameterType.Name | Should -Be 'SwitchParameter'
    }
}
