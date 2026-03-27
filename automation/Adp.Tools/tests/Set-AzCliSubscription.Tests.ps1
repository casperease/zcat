Describe 'Set-AzCliSubscription' {
    It 'is exported and callable' {
        Get-Command Set-AzCliSubscription | Should -Not -BeNullOrEmpty
    }

    It 'has mandatory Subscription parameter' {
        $param = (Get-Command Set-AzCliSubscription).Parameters['Subscription']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
    }
}
