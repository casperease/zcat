<#
.SYNOPSIS
    Returns the current $LASTEXITCODE value, or warns if none exists.
.EXAMPLE
    Get-LastExitCode
    # Returns the exit code from the last native command
#>
function Get-LastExitCode {
    [CmdletBinding()]
    param()

    $exitVar = Get-Variable LASTEXITCODE -Scope Global -ErrorAction Ignore

    if (-not $exitVar) {
        Write-Verbose 'No LASTEXITCODE exists'
        return
    }

    $exitVar.Value
}
