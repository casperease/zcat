<#
.SYNOPSIS
    Lists all exported automation functions.
.DESCRIPTION
    Enumerates all non-dot-prefixed module folders under the automation root,
    finds the matching loaded modules, and returns their exported functions.

    With -NotUsedInternally, filters to functions that are never called by
    another automation function (no incoming edges in the call graph).
.PARAMETER NotUsedInternally
    Only return functions that have no incoming calls from other automation functions.
.PARAMETER AutomationRoot
    Path to the automation directory. Defaults to $env:RepositoryRoot/automation.
.EXAMPLE
    Get-AutomationFunctions
.EXAMPLE
    Get-AutomationFunctions -NotUsedInternally
#>
function Get-AutomationFunctions {
    [CmdletBinding()]
    param(
        [switch] $NotUsedInternally,
        [string] $AutomationRoot = (Join-Path $env:RepositoryRoot 'automation')
    )

    $moduleNames = (Get-ChildItem $AutomationRoot -Directory |
        Where-Object { $_.Name -notmatch '^\.' }).Name

    $modules = Get-Module | Where-Object { $_.Name -in $moduleNames }

    $functions = foreach ($mod in $modules) {
        foreach ($name in $mod.ExportedFunctions.Keys) {
            [PSCustomObject]@{
                Function = $name
                Module   = $mod.Name
            }
        }
    }

    if ($NotUsedInternally) {
        $called = Get-FunctionDependency -AutomationRoot $AutomationRoot |
            ForEach-Object { $_.TargetFunction } |
            Sort-Object -Unique
        $functions = $functions | Where-Object { $_.Function -notin $called }
    }

    $functions | Sort-Object Module, Function
}
