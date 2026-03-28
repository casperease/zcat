Describe 'Connect-AzCli' {
    It 'is exported and callable' {
        Get-Command Connect-AzCli | Should -Not -BeNullOrEmpty
    }

    It 'has Interactive as default parameter set' {
        (Get-Command Connect-AzCli).DefaultParameterSet | Should -Be 'Interactive'
    }

    It 'has ServicePrincipal parameter set with required params' {
        $cmd = Get-Command Connect-AzCli
        $cmd.Parameters['Tenant'] | Should -Not -BeNullOrEmpty
        $cmd.Parameters['ClientId'] | Should -Not -BeNullOrEmpty
        $cmd.Parameters['ClientSecret'] | Should -Not -BeNullOrEmpty
    }

    It 'has DeviceCode switch' {
        $param = (Get-Command Connect-AzCli).Parameters['DeviceCode']
        $param | Should -Not -BeNullOrEmpty
        $param.SwitchParameter | Should -BeTrue
    }

    It 'has ManagedIdentity switch' {
        $param = (Get-Command Connect-AzCli).Parameters['ManagedIdentity']
        $param | Should -Not -BeNullOrEmpty
        $param.SwitchParameter | Should -BeTrue
    }
}
