Describe 'Invoke-AzCli' {
    It 'builds correct command via -DryRun' {
        Invoke-AzCli 'account show' -DryRun | Should -Be 'az account show'
    }

    It 'builds correct multi-arg command via -DryRun' {
        Invoke-AzCli 'group list --output table' -DryRun | Should -Be 'az group list --output table'
    }
}
