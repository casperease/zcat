<#
.SYNOPSIS
    Custom PSScriptAnalyzer rule: forbid semicolons except in for loop headers
    and inline hash table literals.
.DESCRIPTION
    Semicolons are unnecessary in PowerShell — statements end at newlines.
    The only permitted semicolons are:
    - Syntactic separators in for loop headers: for ($i = 0; $i -lt $n; $i++)
    - Entry separators in inline hash tables: @{ A = 1; B = 2 }

    See ADR: never-use-semicolons.
#>

function Measure-NoSemicolons {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    # Only process the root scriptblock to avoid duplicate diagnostics.
    if ($ScriptBlockAst.Parent) {
        return @()
    }

    $results = [System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]]::new()
    $ruleName = 'Measure-NoSemicolons'

    # Tokenize the script to find semicolon tokens.
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput(
        $ScriptBlockAst.Extent.Text, [ref]$tokens, [ref]$errors
    )

    $semicolons = $tokens | Where-Object { $_.Kind -eq 'Semi' }
    if (-not $semicolons) {
        return @()
    }

    # Collect exempt ranges: for-loop headers and hash table literals.

    $exemptRanges = @()

    # For-loop headers (from 'for' keyword to body start) — semicolons are required syntax.
    $forStatements = $ScriptBlockAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.ForStatementAst]
    }, $true)
    foreach ($forStmt in $forStatements) {
        $exemptRanges += @{
            Start = $forStmt.Extent.StartOffset
            End   = $forStmt.Body.Extent.StartOffset
        }
    }

    # Inline hash table literals — semicolons separate entries on one line: @{ A = 1; B = 2 }
    $hashtables = $ScriptBlockAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.HashtableAst]
    }, $true)
    foreach ($ht in $hashtables) {
        $exemptRanges += @{
            Start = $ht.Extent.StartOffset
            End   = $ht.Extent.EndOffset
        }
    }

    foreach ($semi in $semicolons) {
        $offset = $semi.Extent.StartOffset

        $exempt = $false
        foreach ($range in $exemptRanges) {
            if ($offset -ge $range.Start -and $offset -lt $range.End) {
                $exempt = $true
                break
            }
        }
        if ($exempt) { continue }

        $results.Add([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
            Message  = 'Do not use semicolons. PowerShell statements are separated by newlines. Put each statement on its own line. See ADR: never-use-semicolons.'
            Extent   = $semi.Extent
            RuleName = $ruleName
            Severity = 'Error'
        })
    }

    return $results.ToArray()
}

Export-ModuleMember -Function Measure-*
