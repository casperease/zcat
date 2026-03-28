Describe 'Install-Tools' {
    It 'is exported and callable' {
        Get-Command Install-Tools | Should -Not -BeNullOrEmpty
    }

    It 'has Force switch parameter' {
        $param = (Get-Command Install-Tools).Parameters['Force']
        $param | Should -Not -BeNullOrEmpty
        $param.ParameterType.Name | Should -Be 'SwitchParameter'
    }
}
