Describe 'Get-ModuleDependency' {
    BeforeAll {
        $script:edges = Get-ModuleDependency
    }

    It 'CallCount is greater than zero for all edges' {
        $edges | ForEach-Object { $_.CallCount | Should -BeGreaterThan 0 }
    }

    It 'works with pipeline input' {
        $piped = Get-FunctionDependency | Get-ModuleDependency
        $piped | Should -Not -BeNullOrEmpty
        $piped.Count | Should -Be $edges.Count
    }
}
