<#
.SYNOPSIS
    Compiles a list of function-to-function calls across all automation modules using AST.
.DESCRIPTION
    Parses every .ps1 file (excluding tests) under the automation root, builds a
    definition map of all functions, then walks each function body for CommandAst
    nodes and cross-references them against the map.
.PARAMETER AutomationRoot
    Path to the automation directory. Defaults to $env:RepositoryRoot/automation.
.EXAMPLE
    Get-FunctionDependency
.EXAMPLE
    Get-FunctionDependency | Where-Object CrossModule
.EXAMPLE
    Get-FunctionDependency | Get-ModuleDependency
#>
function Get-FunctionDependency {
    [CmdletBinding()]
    param(
        [string] $AutomationRoot = (Join-Path $env:RepositoryRoot 'automation')
    )

    $moduleDirs = Get-ChildItem $AutomationRoot -Directory |
        Where-Object { $_.Name -notmatch '^\.' }

    # Step 1: build definition map — function name → module, file, line
    $definitions = @{}
    foreach ($mod in $moduleDirs) {
        $ps1Files = Get-ChildItem $mod.FullName -Filter '*.ps1' -Recurse |
            Where-Object { $_.Name -notlike '*.Tests.ps1' }

        foreach ($file in $ps1Files) {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $file.FullName, [ref]$tokens, [ref]$errors
            )
            $fns = $ast.FindAll(
                { param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },
                $false
            ) | Where-Object { $_.Parent.Parent -eq $ast }

            foreach ($fn in $fns) {
                $definitions[$fn.Name] = @{
                    Module = $mod.Name
                    File   = $file.Name
                    Line   = $fn.Extent.StartLineNumber
                }
            }
        }
    }

    # Step 2: walk each function body for calls → cross-reference
    foreach ($mod in $moduleDirs) {
        $ps1Files = Get-ChildItem $mod.FullName -Filter '*.ps1' -Recurse |
            Where-Object { $_.Name -notlike '*.Tests.ps1' }

        foreach ($file in $ps1Files) {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $file.FullName, [ref]$tokens, [ref]$errors
            )
            $fns = $ast.FindAll(
                { param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },
                $false
            ) | Where-Object { $_.Parent.Parent -eq $ast }

            foreach ($fn in $fns) {
                $calls = $fn.Body.FindAll(
                    { param($n) $n -is [System.Management.Automation.Language.CommandAst] },
                    $true
                )
                foreach ($call in $calls) {
                    $cmdName = $call.GetCommandName()
                    if (-not $cmdName -or -not $definitions.ContainsKey($cmdName)) { continue }

                    $target = $definitions[$cmdName]
                    [PSCustomObject]@{
                        CallerModule   = $mod.Name
                        CallerFunction = $fn.Name
                        CallerFile     = $file.Name
                        CallerLine     = $call.Extent.StartLineNumber
                        TargetModule   = $target.Module
                        TargetFunction = $cmdName
                        CrossModule    = $mod.Name -ne $target.Module
                    }
                }
            }
        }
    }
}
