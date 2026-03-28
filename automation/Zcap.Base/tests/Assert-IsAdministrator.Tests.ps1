Describe 'Assert-IsAdministrator' {
    It 'is exported and callable' {
        Get-Command Assert-IsAdministrator | Should -Not -BeNullOrEmpty
    }
}
