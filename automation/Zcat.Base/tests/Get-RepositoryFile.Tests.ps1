Describe 'Get-RepositoryFile' {
    It 'joins relative path to repository root' {
        $result = Get-RepositoryFile 'importer.ps1'
        $result | Should -Be (Join-Path $env:RepositoryRoot 'importer.ps1')
    }

    It 'returns a path that exists for a known file' {
        Test-Path (Get-RepositoryFile 'importer.ps1') | Should -BeTrue
    }
}
