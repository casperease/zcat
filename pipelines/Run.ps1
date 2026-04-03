<#
.SYNOPSIS
    Universal pipeline entry point. Bootstraps the module system and executes a command.
.DESCRIPTION
    Called by the invoke-automation.yaml step template. Imports all modules via
    importer.ps1, sanitizes the command string (YAML/ADO escaping artifacts),
    sets up the error trap, then executes the command.

    The command runs in the same scope as the importer — all functions are available
    without module qualification.
.PARAMETER Command
    The PowerShell command string to execute. This should be the same command a
    developer would type after running .\importer.ps1 locally.
    Supports multiline commands (use YAML pipe operator in the template).
#>
param(
    [Parameter(Mandatory)]
    [string] $Command
)

. $PSScriptRoot/../importer.ps1
trap {
    Write-Exception $_
    break
}

$sanitized = ConvertFrom-PipelineCommand $Command
Write-Header 'Invoke-Automation executing:' -ForegroundColor DarkBlue
Write-Information $sanitized
Write-Header -ForegroundColor Blue

$block = [ScriptBlock]::Create($sanitized)
Invoke-Command -ScriptBlock $block -NoNewScope
