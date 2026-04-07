Describe 'Invoke-Dotnet' {
    It 'builds correct command via -DryRun' {
        Invoke-Dotnet 'build' -DryRun | Should -Be 'dotnet build'
    }

    It 'builds correct multi-arg command via -DryRun' {
        Invoke-Dotnet 'test --no-build' -DryRun | Should -Be 'dotnet test --no-build'
    }
}
