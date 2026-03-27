Describe 'Install-Poetry' {
    It 'is exported and callable' {
        Get-Command Install-Poetry | Should -Not -BeNullOrEmpty
    }

    It 'has optional Version parameter' {
        $param = (Get-Command Install-Poetry).Parameters['Version']
        $param | Should -Not -BeNullOrEmpty
    }
}
