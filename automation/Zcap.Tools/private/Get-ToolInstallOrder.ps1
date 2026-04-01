<#
.SYNOPSIS
    Returns tool names from tools.yml in dependency-safe install order.
.DESCRIPTION
    Performs a topological sort based on DependsOn fields. Tools with no
    dependencies come first, tools that depend on others come after their
    dependencies. Throws on circular dependencies.
.EXAMPLE
    Get-ToolInstallOrder
    # Returns @('Python', 'Java', 'Dotnet', 'NodeJs', 'Terraform', 'Poetry', 'AzCli', 'PySpark')
#>
function Get-ToolInstallOrder {
    [OutputType([string[]])]
    [CmdletBinding()]
    param()

    $configPath = Join-Path $PSScriptRoot '..' 'assets' 'config' 'tools.yml'
    Assert-PathExist $configPath
    $allTools = Get-Content $configPath -Raw | ConvertFrom-Yaml

    # Build adjacency: tool → list of tools it depends on
    $deps = @{}
    foreach ($name in $allTools.Keys) {
        $dep = $allTools[$name].DependsOn
        $deps[$name] = if ($dep) { @($dep) } else { @() }
    }

    # Kahn's algorithm — topological sort
    $order = [System.Collections.Generic.List[string]]::new()
    $noDeps = [System.Collections.Generic.Queue[string]]::new()

    # In-degree: how many tools depend on me being installed first
    $inDegree = @{}
    foreach ($name in $deps.Keys) { $inDegree[$name] = 0 }
    foreach ($name in $deps.Keys) {
        foreach ($d in $deps[$name]) {
            $inDegree[$d] = ($inDegree[$d] ?? 0) + 0  # ensure key exists
            $inDegree[$name]++
        }
    }

    # Wait — in-degree is wrong above. In-degree for a node = number of edges pointing TO it.
    # DependsOn means "I depend on X" = edge from X to me. So in-degree of me = count of my DependsOn.
    # Actually no: in Kahn's for install order, we want: if A depends on B, B must come first.
    # So edge is B → A (B must be installed before A). In-degree of A = number of dependencies A has.

    # Redo properly
    $inDegree = @{}
    foreach ($name in $deps.Keys) {
        $inDegree[$name] = $deps[$name].Count
    }

    foreach ($name in $deps.Keys) {
        if ($inDegree[$name] -eq 0) {
            $noDeps.Enqueue($name)
        }
    }

    while ($noDeps.Count -gt 0) {
        $current = $noDeps.Dequeue()
        $order.Add($current)

        # Find all tools that depend on $current and reduce their in-degree
        foreach ($name in $deps.Keys) {
            if ($deps[$name] -contains $current) {
                $inDegree[$name]--
                if ($inDegree[$name] -eq 0) {
                    $noDeps.Enqueue($name)
                }
            }
        }
    }

    if ($order.Count -ne $deps.Count) {
        $missing = $deps.Keys | Where-Object { $_ -notin $order }
        throw "Circular dependency detected among tools: $($missing -join ', ')"
    }

    $order.ToArray()
}
