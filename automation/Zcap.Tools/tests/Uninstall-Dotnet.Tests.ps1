Describe 'Uninstall-Dotnet' {
    It 'is exported and callable' {
        Get-Command Uninstall-Dotnet | Should -Not -BeNullOrEmpty
    }
}
