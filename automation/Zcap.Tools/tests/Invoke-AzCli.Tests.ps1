Describe 'Invoke-AzCli' {
    It 'is exported and callable' {
        Get-Command Invoke-AzCli | Should -Not -BeNullOrEmpty
    }

    It 'has mandatory Arguments parameter' {
        $param = (Get-Command Invoke-AzCli).Parameters['Arguments']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
    }

    It 'builds correct command via -DryRun' {
        Invoke-AzCli 'account show' -DryRun | Should -Be 'az account show'
    }

    It 'builds correct multi-arg command via -DryRun' {
        Invoke-AzCli 'group list --output table' -DryRun | Should -Be 'az group list --output table'
    }
}
