Describe 'Get-ToolInstallOrder' {
    BeforeAll {
        $script:order = & (Get-Module Zcap.Tools) { Get-ToolInstallOrder }
        $script:configPath = Join-Path $PSScriptRoot '../assets/config/tools.yml'
        $script:allTools = Get-Content $configPath -Raw | ConvertFrom-Yaml
    }

    It 'returns all tools from tools.yml' {
        $order.Count | Should -Be $allTools.Keys.Count
    }

    It 'returns each tool exactly once' {
        ($order | Select-Object -Unique).Count | Should -Be $order.Count
    }

    It 'only contains tools defined in tools.yml' {
        foreach ($name in $order) {
            $allTools.Keys | Should -Contain $name
        }
    }

    It 'dependencies come before dependents' {
        foreach ($name in $allTools.Keys) {
            $dep = $allTools[$name]['DependsOn']
            if ($dep) {
                $depIndex = [array]::IndexOf($order, $dep)
                $toolIndex = [array]::IndexOf($order, $name)
                $depIndex | Should -BeLessThan $toolIndex -Because "$name depends on $dep"
            }
        }
    }

    It 'Python comes before AzCli' {
        $pythonIdx = [array]::IndexOf($order, 'Python')
        $azIdx = [array]::IndexOf($order, 'AzCli')
        $pythonIdx | Should -BeLessThan $azIdx
    }

    It 'Python comes before Poetry' {
        $pythonIdx = [array]::IndexOf($order, 'Python')
        $poetryIdx = [array]::IndexOf($order, 'Poetry')
        $pythonIdx | Should -BeLessThan $poetryIdx
    }

    It 'Java comes before PySpark' {
        $javaIdx = [array]::IndexOf($order, 'Java')
        $pysparkIdx = [array]::IndexOf($order, 'PySpark')
        $javaIdx | Should -BeLessThan $pysparkIdx
    }
}
