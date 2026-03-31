<#
.SYNOPSIS
    Custom PSScriptAnalyzer rule: forbid use of $?.
.DESCRIPTION
    $? is overwritten by every statement, making it impossible to check
    reliably. Use -ErrorAction Stop and try/catch for cmdlets, or
    Assert-LastExitCodeWasZero for native commands.

    See ADR: automatic-variable-pitfalls.
#>

function Measure-NoAutomaticVariableMisuse {
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
    $ruleName = 'Measure-NoAutomaticVariableMisuse'

    $variables = $ScriptBlockAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.VariableExpressionAst] -and
        $node.VariablePath.UserPath -eq '?'
    }, $true)

    foreach ($var in $variables) {
        $results.Add([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
            Message  = 'Do not use $?. It is overwritten by every statement and cannot be checked reliably. Use -ErrorAction Stop and try/catch for cmdlets, or Assert-LastExitCodeWasZero for native commands. See ADR: automatic-variable-pitfalls.'
            Extent   = $var.Extent
            RuleName = $ruleName
            Severity = 'Error'
        })
    }

    return $results.ToArray()
}

Export-ModuleMember -Function Measure-*
