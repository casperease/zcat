Describe 'Install-DevBox' {
    It 'is exported and callable' {
        Get-Command Install-DevBox | Should -Not -BeNullOrEmpty
    }

    It 'has Force switch parameter' {
        $param = (Get-Command Install-DevBox).Parameters['Force']
        $param | Should -Not -BeNullOrEmpty
        $param.ParameterType.Name | Should -Be 'SwitchParameter'
    }
}
