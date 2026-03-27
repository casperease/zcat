Describe 'Install-VendorModule' {
    It 'is exported and callable' {
        Get-Command Install-VendorModule | Should -Not -BeNullOrEmpty
    }
}
