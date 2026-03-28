Describe 'Assert-DevBoxStatus' {
    It 'is exported and callable' {
        Get-Command Assert-DevBoxStatus | Should -Not -BeNullOrEmpty
    }
}
