Describe 'Get-FunctionDependency' {
    BeforeAll {
        $script:deps = Get-FunctionDependency
    }

    It 'returns results' {
        $deps | Should -Not -BeNullOrEmpty
    }

    It 'has expected properties' {
        $first = $deps | Select-Object -First 1
        $first.PSObject.Properties.Name | Should -Contain 'CallerModule'
        $first.PSObject.Properties.Name | Should -Contain 'CallerFunction'
        $first.PSObject.Properties.Name | Should -Contain 'CallerFile'
        $first.PSObject.Properties.Name | Should -Contain 'CallerLine'
        $first.PSObject.Properties.Name | Should -Contain 'TargetModule'
        $first.PSObject.Properties.Name | Should -Contain 'TargetFunction'
        $first.PSObject.Properties.Name | Should -Contain 'CrossModule'
    }

    It 'includes cross-module dependencies' {
        $cross = $deps | Where-Object CrossModule
        $cross | Should -Not -BeNullOrEmpty
    }

    It 'includes intra-module dependencies' {
        $intra = $deps | Where-Object { -not $_.CrossModule }
        $intra | Should -Not -BeNullOrEmpty
    }

    It 'CrossModule is true when CallerModule != TargetModule' {
        $deps | Where-Object CrossModule | ForEach-Object {
            $_.CallerModule | Should -Not -Be $_.TargetModule
        }
    }
}
