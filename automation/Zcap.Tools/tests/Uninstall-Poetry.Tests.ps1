Describe 'Uninstall-Poetry' {
    It 'is exported and callable' {
        Get-Command Uninstall-Poetry | Should -Not -BeNullOrEmpty
    }

    It 'has optional Version parameter' {
        $param = (Get-Command Uninstall-Poetry).Parameters['Version']
        $param | Should -Not -BeNullOrEmpty
    }
}
