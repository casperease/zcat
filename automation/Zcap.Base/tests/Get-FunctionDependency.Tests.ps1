Describe 'Get-FunctionDependency' {
    BeforeAll {
        $script:deps = Get-FunctionDependency
    }

    It 'CrossModule is true when CallerModule != TargetModule' {
        $deps | Where-Object CrossModule | ForEach-Object {
            $_.CallerModule | Should -Not -Be $_.TargetModule
        }
    }
}
