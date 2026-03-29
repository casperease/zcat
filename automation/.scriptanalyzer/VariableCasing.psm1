<#
.SYNOPSIS
    Custom PSScriptAnalyzer rule: enforce variable casing conventions.
.DESCRIPTION
    PascalCase: parameters, $global: scoped variables.
    camelCase: local (unscoped), $script:, and $private: scoped variables.
    Scriptblock params and automatic variables are skipped.
#>

# Automatic / preference / well-known variables that should not be flagged
$script:skipVariables = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@(
        '_', 'PSItem', 'this', 'null', 'true', 'false',
        'PSCmdlet', 'PSBoundParameters', 'MyInvocation', 'ExecutionContext',
        'PSScriptRoot', 'PSCommandPath', 'PSDefaultParameterValues',
        'ErrorActionPreference', 'InformationPreference', 'WarningPreference',
        'DebugPreference', 'VerbosePreference', 'ProgressPreference',
        'ConfirmPreference', 'WhatIfPreference',
        'LASTEXITCODE', 'PROFILE', 'HOME', 'Host', 'PID', 'PWD', 'ShellId',
        'StackTrace', 'Error', 'Event', 'EventArgs', 'EventSubscriber', 'Sender',
        'Matches', 'OFS', 'FormatEnumerationLimit', 'MaximumHistoryCount',
        'input', 'args', 'ConsoleFileName', 'NestedPromptLevel',
        'IsWindows', 'IsMacOS', 'IsLinux', 'IsCoreCLR', 'ErrorView'
    ),
    [System.StringComparer]::OrdinalIgnoreCase
)

function Measure-VariableCasing {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    $results = [System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]]::new()
    $ruleName = 'Measure-VariableCasing'

    # Collect all parameter names (for excluding from local-variable check)
    $paramNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $params = $ScriptBlockAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.ParameterAst]
    }, $true)

    foreach ($p in $params) {
        $name = $p.Name.VariablePath.UserPath
        $paramNames.Add($name) | Out-Null

        # Skip scriptblock params (e.g. { param($n) ... } in FindAll predicates)
        # Named function: ParamBlockAst → ScriptBlockAst → FunctionDefinitionAst
        # Scriptblock:    ParamBlockAst → ScriptBlockAst → ScriptBlockExpressionAst
        $parentOfScript = $p.Parent.Parent.Parent
        if ($parentOfScript -isnot [System.Management.Automation.Language.FunctionDefinitionAst]) { continue }

        # Parameters must start uppercase (PascalCase)
        if ($name.Length -gt 0 -and $name[0] -cmatch '[a-z]') {
            $results.Add([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                Message  = "Parameter '`$$name' should start with an uppercase letter."
                Extent   = $p.Extent
                RuleName = $ruleName
                Severity = 'Warning'
            })
        }
    }

    # Check variable assignments
    $assignments = $ScriptBlockAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.AssignmentStatementAst]
    }, $true)

    foreach ($a in $assignments) {
        $left = $a.Left
        if ($left -isnot [System.Management.Automation.Language.VariableExpressionAst]) { continue }

        $varPath = $left.VariablePath
        # Skip $env: drive variables (casing is OS-dependent)
        if ($varPath.DriveName) { continue }

        # In test files, $script: is Pester's way of sharing state between It blocks — treat as local
        $isTestFile = $ScriptBlockAst.Extent.File -like '*.Tests.ps1'
        $isScoped = -not $isTestFile -and $varPath.IsGlobal

        $name = $varPath.UserPath
        # Strip scope prefix for the casing check (script:Foo → Foo)
        if ($name -match '^(script|global|private):(.+)$') { $name = $Matches[2] }
        if ($paramNames.Contains($name)) { continue }
        if ($script:skipVariables.Contains($name)) { continue }

        if ($isScoped) {
            # Scoped variables ($script:, $global:) must start uppercase (PascalCase)
            if ($name.Length -gt 0 -and $name[0] -cmatch '[a-z]') {
                $results.Add([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                    Message  = "Scoped variable '`$$($varPath.UserPath)' should start with an uppercase letter."
                    Extent   = $left.Extent
                    RuleName = $ruleName
                    Severity = 'Warning'
                })
            }
        }
        else {
            # Local variables must start lowercase (camelCase)
            if ($name.Length -gt 0 -and $name[0] -cmatch '[A-Z]') {
                $results.Add([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                    Message  = "Local variable '`$$name' should start with a lowercase letter."
                    Extent   = $left.Extent
                    RuleName = $ruleName
                    Severity = 'Warning'
                })
            }
        }
    }

    return $results.ToArray()
}

Export-ModuleMember -Function Measure-*
