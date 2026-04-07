<#
.SYNOPSIS
    Returns the transitive closure of all functions that a given function depends on.
.DESCRIPTION
    Takes a function name and walks the call graph produced by Get-FunctionDependency
    using breadth-first search. Returns every function reachable from the root, with
    the depth at which it was first encountered and the caller that introduced it.

    Accepts pipeline input from Get-FunctionDependency. If no pipeline input is
    provided, calls Get-FunctionDependency automatically.
.PARAMETER Function
    The name of the root function to trace dependencies from.
.PARAMETER Dependency
    Function dependency objects from Get-FunctionDependency. Accepts pipeline input.
.EXAMPLE
    Get-FunctionDependencyTree -Function 'Install-Poetry'
.EXAMPLE
    Get-FunctionDependency | Get-FunctionDependencyTree -Function 'Get-ModuleDependency'
#>
function Get-FunctionDependencyTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Function,

        [Parameter(ValueFromPipeline)]
        [PSObject[]] $Dependency
    )

    begin { $all = [System.Collections.Generic.List[PSObject]]::new() }
    process { foreach ($d in $Dependency) { $all.Add($d) } }
    end {
        if ($all.Count -eq 0) {
            $all.AddRange([PSObject[]](Get-FunctionDependency))
        }

        # Build adjacency list: caller -> list of edges
        $adjacency = @{}
        foreach ($edge in $all) {
            if (-not $adjacency.ContainsKey($edge.CallerFunction)) {
                $adjacency[$edge.CallerFunction] = [System.Collections.Generic.List[PSObject]]::new()
            }
            $adjacency[$edge.CallerFunction].Add($edge)
        }

        $callerExists = $adjacency.ContainsKey($Function) -or ($all | Where-Object { $_.TargetFunction -eq $Function } | Select-Object -First 1)
        Assert-True ([bool]$callerExists) -ErrorText "Function '$Function' not found in dependency graph"

        # BFS
        $visited = [System.Collections.Generic.HashSet[string]]::new()
        $queue = [System.Collections.Generic.Queue[PSObject]]::new()

        # Seed with direct dependencies
        if ($adjacency.ContainsKey($Function)) {
            foreach ($edge in $adjacency[$Function]) {
                if ($visited.Add($edge.TargetFunction)) {
                    $queue.Enqueue([PSCustomObject]@{
                        Function       = $edge.TargetFunction
                        Module         = $edge.TargetModule
                        Depth          = 1
                        CallerFunction = $edge.CallerFunction
                        CallerFile     = $edge.CallerFile
                        CallerLine     = $edge.CallerLine
                    })
                }
            }
        }

        while ($queue.Count -gt 0) {
            $current = $queue.Dequeue()
            $current

            $nextDepth = $current.Depth + 1
            if ($adjacency.ContainsKey($current.Function)) {
                foreach ($edge in $adjacency[$current.Function]) {
                    if ($visited.Add($edge.TargetFunction)) {
                        $queue.Enqueue([PSCustomObject]@{
                            Function       = $edge.TargetFunction
                            Module         = $edge.TargetModule
                            Depth          = $nextDepth
                            CallerFunction = $edge.CallerFunction
                            CallerFile     = $edge.CallerFile
                            CallerLine     = $edge.CallerLine
                        })
                    }
                }
            }
        }
    }
}
