<#
.SYNOPSIS
    Custom PSScriptAnalyzer rule: forbid Az module naming conventions.
.DESCRIPTION
    Functions must not use the Verb-Az* naming pattern used by Az PowerShell
    modules. The only permitted pattern is Verb-AzCli*, which is our convention
    for Azure CLI wrapper functions. This enforces the ADR decision to prefer
    Az CLI over Az PowerShell modules.
#>

function Measure-NoAzModuleNaming {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    $results = [System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]]::new()

    $functions = $ScriptBlockAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true)

    foreach ($fn in $functions) {
        if ($fn.Name -match '^\w+-Az' -and $fn.Name -notmatch '^\w+-AzCli') {
            $results.Add([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                Message  = "Function '$($fn.Name)' uses Az module naming (Verb-Az*). Use Verb-AzCli* for Azure CLI wrappers, or choose a name that does not collide with Az PowerShell modules."
                Extent   = $fn.Extent
                RuleName = 'Measure-NoAzModuleNaming'
                Severity = 'Warning'
            })
        }
    }

    return $results.ToArray()
}

Export-ModuleMember -Function Measure-*
