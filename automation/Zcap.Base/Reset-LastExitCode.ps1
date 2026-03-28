<#
.SYNOPSIS
    Removes the global $LASTEXITCODE variable.
.EXAMPLE
    Reset-LastExitCode
#>
function Reset-LastExitCode {
    [CmdletBinding()]
    param()

    $exitVar = Get-Variable LASTEXITCODE -Scope Global -ErrorAction Ignore
    if ($exitVar) {
        Remove-Variable LASTEXITCODE -Scope Global
    }
}
