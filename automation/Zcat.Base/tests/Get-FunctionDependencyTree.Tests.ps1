Describe 'Get-FunctionDependencyTree' {
    BeforeAll {
        # Build a synthetic dependency graph
        $script:graph = @(
            [PSCustomObject]@{ CallerModule = 'A'; CallerFunction = 'Invoke-Root'; CallerFile = 'Invoke-Root.ps1'; CallerLine = 5; TargetModule = 'B'; TargetFunction = 'Get-Middle'; CrossModule = $true }
            [PSCustomObject]@{ CallerModule = 'B'; CallerFunction = 'Get-Middle'; CallerFile = 'Get-Middle.ps1'; CallerLine = 3; TargetModule = 'C'; TargetFunction = 'Get-Leaf'; CrossModule = $true }
            [PSCustomObject]@{ CallerModule = 'A'; CallerFunction = 'Invoke-Root'; CallerFile = 'Invoke-Root.ps1'; CallerLine = 8; TargetModule = 'C'; TargetFunction = 'Get-Leaf'; CrossModule = $true }
        )
    }

    It 'returns direct dependencies at depth 1' {
        $result = $graph | Get-FunctionDependencyTree -Function 'Invoke-Root'
        $direct = $result | Where-Object { $_.Depth -eq 1 }
        $direct.Function | Should -Contain 'Get-Middle'
    }

    It 'returns transitive dependencies at depth > 1' {
        $result = $graph | Get-FunctionDependencyTree -Function 'Invoke-Root'
        $result.Function | Should -Contain 'Get-Leaf'
    }

    It 'does not include the root function itself' {
        $result = $graph | Get-FunctionDependencyTree -Function 'Invoke-Root'
        $result.Function | Should -Not -Contain 'Invoke-Root'
    }

    It 'returns each dependency only once' {
        $result = $graph | Get-FunctionDependencyTree -Function 'Invoke-Root'
        $leafCount = ($result | Where-Object { $_.Function -eq 'Get-Leaf' }).Count
        $leafCount | Should -Be 1
    }

    It 'returns empty for a leaf function with no outgoing calls' {
        $result = $graph | Get-FunctionDependencyTree -Function 'Get-Leaf'
        $result | Should -BeNullOrEmpty
    }

    It 'accepts pipeline input from Get-FunctionDependency' {
        $result = $graph | Get-FunctionDependencyTree -Function 'Invoke-Root'
        $result | Should -Not -BeNullOrEmpty
    }
}
