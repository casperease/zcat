Describe 'Uninstall-Dotnet' {
    It 'is exported and callable' {
        Get-Command Uninstall-Dotnet | Should -Not -BeNullOrEmpty
    }

    It 'has optional Version parameter' {
        $param = (Get-Command Uninstall-Dotnet).Parameters['Version']
        $param | Should -Not -BeNullOrEmpty
        $param.ParameterType.Name | Should -Be 'String'
    }
}
