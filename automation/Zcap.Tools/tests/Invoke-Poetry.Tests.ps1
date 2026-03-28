Describe 'Invoke-Poetry' {
    It 'is exported and callable' {
        Get-Command Invoke-Poetry | Should -Not -BeNullOrEmpty
    }

    It 'has mandatory Arguments parameter' {
        $param = (Get-Command Invoke-Poetry).Parameters['Arguments']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
    }

    It 'builds correct command via -DryRun' {
        Invoke-Poetry 'install' -DryRun | Should -Be 'poetry install'
    }
}
