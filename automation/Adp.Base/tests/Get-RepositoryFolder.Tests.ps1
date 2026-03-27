Describe 'Get-RepositoryFolder' {
    It 'joins relative path to repository root' {
        $result = Get-RepositoryFolder 'automation/PseCore'
        $result | Should -Be (Join-Path $env:RepositoryRoot 'automation/PseCore')
    }

    It 'returns a path that exists for a known folder' {
        Test-Path (Get-RepositoryFolder 'automation') | Should -BeTrue
    }
}
