<#
.SYNOPSIS
    Displays all environment variables sorted by name.
.EXAMPLE
    Write-EnvironmentDiagnostic
#>
function Write-EnvironmentDiagnostic {
    [CmdletBinding()]
    param()

    Get-ChildItem env: |
    Select-Object Name, Value |
    Sort-Object Name |
    Format-Table -Property @{ Expression = 'Name'; Width = 40 }, Value
}
