Describe 'Invoke-Dotnet' {
    It 'is exported and callable' {
        Get-Command Invoke-Dotnet | Should -Not -BeNullOrEmpty
    }

    It 'has mandatory Arguments parameter' {
        $param = (Get-Command Invoke-Dotnet).Parameters['Arguments']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
    }

    It 'builds correct command via -DryRun' {
        Invoke-Dotnet 'build' -DryRun | Should -Be 'dotnet build'
    }

    It 'builds correct multi-arg command via -DryRun' {
        Invoke-Dotnet 'test --no-build' -DryRun | Should -Be 'dotnet test --no-build'
    }
}
