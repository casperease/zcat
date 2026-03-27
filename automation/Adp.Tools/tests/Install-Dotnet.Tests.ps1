Describe 'Install-Dotnet' {
    It 'is exported and callable' {
        Get-Command Install-Dotnet | Should -Not -BeNullOrEmpty
    }

    It 'has optional Version parameter' {
        $param = (Get-Command Install-Dotnet).Parameters['Version']
        $param | Should -Not -BeNullOrEmpty
        $param.ParameterType.Name | Should -Be 'String'
    }
}
