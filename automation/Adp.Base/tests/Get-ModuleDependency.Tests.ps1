Describe 'Get-ModuleDependency' {
    BeforeAll {
        $script:edges = Get-ModuleDependency
    }

    It 'returns results' {
        $edges | Should -Not -BeNullOrEmpty
    }

    It 'has expected properties' {
        $first = $edges | Select-Object -First 1
        $first.PSObject.Properties.Name | Should -Contain 'From'
        $first.PSObject.Properties.Name | Should -Contain 'To'
        $first.PSObject.Properties.Name | Should -Contain 'CallCount'
        $first.PSObject.Properties.Name | Should -Contain 'Functions'
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
