Describe 'Uninstall-DevBox' {
    It 'is exported and callable' {
        Get-Command Uninstall-DevBox | Should -Not -BeNullOrEmpty
    }
}
