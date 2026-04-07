<#
.SYNOPSIS
    Tests whether all function-to-function calls resolve to a defined command.
.DESCRIPTION
    Parses every .ps1 file (excluding tests) under the automation root using AST,
    then checks each function call against: (a) the definitions map of automation
    functions, and (b) Get-Command for built-ins, vendor modules, and other loaded
    commands.

    Returns $true when all calls resolve, $false when any are unresolved.
    Unresolved calls are written to the Verbose stream with caller and target details.

    Must run post-import so Get-Command covers all loaded modules.
.PARAMETER AutomationRoot
    Path to the automation directory. Defaults to $env:RepositoryRoot/automation.
.EXAMPLE
    Test-FunctionDependency
.EXAMPLE
    Test-FunctionDependency -Verbose
#>
function Test-FunctionDependency {
    [CmdletBinding()]
    [OutputType([bool])]
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

    # Step 2: walk each function body for calls → check resolution
    $unresolved = [System.Collections.Generic.List[PSObject]]::new()

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
                # Collect nested function names defined inside this function body
                $nestedNames = $fn.Body.FindAll(
                    { param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },
                    $true
                ) | ForEach-Object { $_.Name }
                $localDefs = [System.Collections.Generic.HashSet[string]]::new(
                    [string[]]@($nestedNames | Where-Object { $_ }),
                    [System.StringComparer]::OrdinalIgnoreCase
                )

                $calls = $fn.Body.FindAll(
                    { param($n) $n -is [System.Management.Automation.Language.CommandAst] },
                    $true
                )
                foreach ($call in $calls) {
                    $cmdName = $call.GetCommandName()
                    if (-not $cmdName) { continue }
                    if ($definitions.ContainsKey($cmdName)) { continue }
                    if ($localDefs.Contains($cmdName)) { continue }
                    if (Get-Command $cmdName -ErrorAction Ignore) { continue }

                    $unresolved.Add([PSCustomObject]@{
                        CallerModule   = $mod.Name
                        CallerFunction = $fn.Name
                        CallerFile     = $file.Name
                        CallerLine     = $call.Extent.StartLineNumber
                        MissingCommand = $cmdName
                    })
                }
            }
        }
    }

    foreach ($entry in $unresolved) {
        Write-Verbose "$($entry.CallerFunction) -> $($entry.MissingCommand) ($($entry.CallerFile):$($entry.CallerLine))"
    }

    $unresolved.Count -eq 0
}
