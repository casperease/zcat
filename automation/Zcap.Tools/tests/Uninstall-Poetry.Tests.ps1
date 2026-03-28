Describe 'Uninstall-Poetry' {
    It 'is exported and callable' {
        Get-Command Uninstall-Poetry | Should -Not -BeNullOrEmpty
    }
}
