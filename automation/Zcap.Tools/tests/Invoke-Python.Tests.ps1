Describe 'Invoke-Python' {
    It 'is exported and callable' {
        Get-Command Invoke-Python | Should -Not -BeNullOrEmpty
    }

    It 'has mandatory Arguments parameter' {
        $param = (Get-Command Invoke-Python).Parameters['Arguments']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
    }

    It 'builds correct command via -DryRun' {
        Invoke-Python '-c "print(42)"' -DryRun | Should -Be 'python -c "print(42)"'
    }

    It 'builds correct multi-arg command via -DryRun' {
        Invoke-Python '-m pip list' -DryRun | Should -Be 'python -m pip list'
    }
}
