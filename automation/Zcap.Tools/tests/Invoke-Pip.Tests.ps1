Describe 'Invoke-Pip' {
    It 'is exported and callable' {
        Get-Command Invoke-Pip | Should -Not -BeNullOrEmpty
    }

    It 'has mandatory Arguments parameter' {
        $param = (Get-Command Invoke-Pip).Parameters['Arguments']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
    }

    It 'builds correct command via -DryRun' {
        Invoke-Pip 'install requests' -DryRun | Should -Be 'python -m pip install requests'
    }
}
