Describe 'Disconnect-AzCli' {
    It 'is exported and callable' {
        Get-Command Disconnect-AzCli | Should -Not -BeNullOrEmpty
    }
}
