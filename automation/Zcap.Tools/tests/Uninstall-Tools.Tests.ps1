Describe 'Uninstall-Tools' {
    It 'is exported and callable' {
        Get-Command Uninstall-Tools | Should -Not -BeNullOrEmpty
    }
}
