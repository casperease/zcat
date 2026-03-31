<#
.SYNOPSIS
    Custom PSScriptAnalyzer rule: forbid return, break, continue inside ForEach-Object.
.DESCRIPTION
    return/break/continue have completely different semantics inside a
    ForEach-Object scriptblock than inside a foreach loop:
    - return exits the scriptblock (acts like continue), not the function
    - break/continue act on the enclosing loop or terminate the script
    If you need control flow, use a foreach statement instead.

    See ADR: prefer-foreach-over-foreach-object.
#>

function Measure-NoForEachObjectControlFlow {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    # PSScriptAnalyzer invokes custom rules for every ScriptBlockAst in the parse tree.
    # FindAll recurses, so only process the root to avoid duplicate diagnostics.
    if ($ScriptBlockAst.Parent) {
        return @()
    }

    $results = [System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]]::new()
    $ruleName = 'Measure-NoForEachObjectControlFlow'

    # Find all ForEach-Object / % command invocations
    $commands = $ScriptBlockAst.FindAll({
        param($node)
        if ($node -isnot [System.Management.Automation.Language.CommandAst]) { return $false }
        $name = $node.GetCommandName()
        return ($name -eq 'ForEach-Object' -or $name -eq '%')
    }, $true)

    foreach ($cmd in $commands) {
        # Collect all scriptblock arguments to this ForEach-Object call.
        # These are the -Process, -Begin, -End blocks or positional scriptblock args.
        $scriptBlocks = @()
        foreach ($element in $cmd.CommandElements) {
            if ($element -is [System.Management.Automation.Language.ScriptBlockExpressionAst]) {
                $scriptBlocks += $element.ScriptBlock
            }
        }

        foreach ($block in $scriptBlocks) {
            # Find return, break, continue statements that are direct children of THIS
            # scriptblock — not inside a nested foreach/for/while/do/switch/function/
            # scriptblock, where they would be valid.
            $statements = $block.FindAll({
                param($node)

                # Match return, break, continue statements
                $isTarget = (
                    $node -is [System.Management.Automation.Language.ReturnStatementAst] -or
                    $node -is [System.Management.Automation.Language.BreakStatementAst] -or
                    $node -is [System.Management.Automation.Language.ContinueStatementAst]
                )
                if (-not $isTarget) { return $false }

                # Walk up the AST to check if there is an intervening loop/switch/function
                # between this statement and the ForEach-Object scriptblock.
                # If there is, the keyword targets that construct — not our scriptblock.
                $parent = $node.Parent
                while ($null -ne $parent -and $parent -ne $block) {
                    # foreach/for/while/do loops — return/break/continue are valid here
                    if ($parent -is [System.Management.Automation.Language.ForEachStatementAst] -or
                        $parent -is [System.Management.Automation.Language.ForStatementAst] -or
                        $parent -is [System.Management.Automation.Language.WhileStatementAst] -or
                        $parent -is [System.Management.Automation.Language.DoWhileStatementAst] -or
                        $parent -is [System.Management.Automation.Language.DoUntilStatementAst]) {
                        return $false
                    }
                    # switch — break is valid here
                    if ($parent -is [System.Management.Automation.Language.SwitchStatementAst] -and
                        $node -is [System.Management.Automation.Language.BreakStatementAst]) {
                        return $false
                    }
                    # Nested function or scriptblock — keywords target that scope, not ours
                    if ($parent -is [System.Management.Automation.Language.FunctionDefinitionAst] -or
                        $parent -is [System.Management.Automation.Language.ScriptBlockExpressionAst]) {
                        return $false
                    }
                    $parent = $parent.Parent
                }

                return $true
            }, $true)

            foreach ($stmt in $statements) {
                $keyword = if ($stmt -is [System.Management.Automation.Language.ReturnStatementAst]) { 'return' }
                    elseif ($stmt -is [System.Management.Automation.Language.BreakStatementAst]) { 'break' }
                    else { 'continue' }

                $message = switch ($keyword) {
                    'return' {
                        "Do not use 'return' inside ForEach-Object. It exits only the current scriptblock iteration (like 'continue' in a loop), not the enclosing function. Use a foreach statement instead. See ADR: prefer-foreach-over-foreach-object."
                    }
                    'break' {
                        "Do not use 'break' inside ForEach-Object. It does not break the pipeline — it breaks the nearest enclosing loop or terminates the script. Use a foreach statement instead. See ADR: prefer-foreach-over-foreach-object."
                    }
                    'continue' {
                        "Do not use 'continue' inside ForEach-Object. It does not skip to the next pipeline item — it acts on the nearest enclosing loop or terminates the script. Use a foreach statement instead. See ADR: prefer-foreach-over-foreach-object."
                    }
                }

                $results.Add([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                    Message  = $message
                    Extent   = $stmt.Extent
                    RuleName = $ruleName
                    Severity = 'Error'
                })
            }
        }
    }

    return $results.ToArray()
}

Export-ModuleMember -Function Measure-*
