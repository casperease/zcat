<#
.SYNOPSIS
    Custom PSScriptAnalyzer rule: forbid Write-Error and Write-Warning.
.DESCRIPTION
    All errors are terminating — use throw or Assert-*.
    All warnings are terminating ($WarningPreference = 'Stop') — there is
    no middle ground between "fine" and "stop." Use Write-Message or
    Write-Information for status, throw for failures.
#>

function Measure-NoWriteErrorOrWarning {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    $results = [System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]]::new()
    $ruleName = 'Measure-NoWriteErrorOrWarning'

    $commands = $ScriptBlockAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst]
    }, $true)

    foreach ($cmd in $commands) {
        $name = $cmd.GetCommandName()
        if ($name -eq 'Write-Error') {
            $results.Add([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                Message  = "Do not use Write-Error. Use 'throw' or an Assert-* function instead."
                Extent   = $cmd.Extent
                RuleName = $ruleName
                Severity = 'Warning'
            })
        }
        elseif ($name -eq 'Write-Warning') {
            $results.Add([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                Message  = "Do not use Write-Warning. Use 'throw' if something is wrong, or Write-Message/Write-Information if it is informational."
                Extent   = $cmd.Extent
                RuleName = $ruleName
                Severity = 'Warning'
            })
        }
    }

    return $results.ToArray()
}

Export-ModuleMember -Function Measure-*
