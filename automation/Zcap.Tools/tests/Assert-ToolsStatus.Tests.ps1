Describe 'Assert-ToolsStatus' {
    It 'is exported and callable' {
        Get-Command Assert-ToolsStatus | Should -Not -BeNullOrEmpty
    }
}
