Describe 'Invoke-Terraform' {
    It 'builds correct command via -DryRun' {
        Invoke-Terraform 'plan' -DryRun | Should -Be 'terraform plan'
    }

    It 'builds correct multi-arg command via -DryRun' {
        Invoke-Terraform 'apply -auto-approve' -DryRun | Should -Be 'terraform apply -auto-approve'
    }
}
