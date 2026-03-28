Describe 'Invoke-Poetry' {
    It 'builds correct command via -DryRun' {
        Invoke-Poetry 'install' -DryRun | Should -Be 'poetry install'
    }
}
