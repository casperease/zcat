<#
.SYNOPSIS
    Sanitizes a command string received from an ADO pipeline step.
.DESCRIPTION
    When ADO passes a command string through YAML template parameters, task
    arguments, and into PowerShell, the string accumulates escaping artifacts:
    carriage returns from Windows line endings, mixed newlines depending on
    whether the YAML source used folding (>) or literal (|) block scalars,
    and trailing whitespace from YAML indentation. By the time the string
    reaches PowerShell, YAML has already been parsed — this function only
    deals with the resulting plain string, not YAML syntax.

    This function normalizes the string for safe use with [ScriptBlock]::Create().
.PARAMETER Command
    The raw command string as received from ADO pipeline arguments.
.EXAMPLE
    ConvertFrom-AdoPipelineCommand "  Get-Process `r`n  Get-Service  "
    # Returns: "Get-Process\nGet-Service"
.EXAMPLE
    # In Invoke-AdoScript.ps1:
    $sanitized = ConvertFrom-AdoPipelineCommand $Command
    $block = [ScriptBlock]::Create($sanitized)
    Invoke-Command -ScriptBlock $block -NoNewScope
#>
function ConvertFrom-AdoPipelineCommand {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string] $Command
    )

    # Normalize line endings: \r\n → \n, stray \r → \n
    $clean = $Command -replace "`r`n", "`n"
    $clean = $clean -replace "`r", "`n"

    # Trim leading/trailing whitespace and blank lines
    $clean = $clean.Trim()

    # Remove trailing whitespace per line (YAML indentation artifacts)
    $clean = ($clean -split "`n" | ForEach-Object { $_.TrimEnd() }) -join "`n"

    $clean
}
