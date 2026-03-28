Describe 'Install-DevBox' {
    It 'is exported and callable' {
        Get-Command Install-DevBox | Should -Not -BeNullOrEmpty
    }
}
