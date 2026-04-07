Describe 'Invoke-Python' {
    It 'builds correct command via -DryRun' {
        Invoke-Python '-c "print(42)"' -DryRun | Should -Be 'python -c "print(42)"'
    }

    It 'builds correct multi-arg command via -DryRun' {
        Invoke-Python '-m pip list' -DryRun | Should -Be 'python -m pip list'
    }
}
