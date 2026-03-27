<#
.SYNOPSIS
    Asserts that $LASTEXITCODE is 0.
.DESCRIPTION
    Checks the global $LASTEXITCODE variable and throws if it is non-zero.
    Resets $LASTEXITCODE after checking unless -DoNotReset is specified.
.PARAMETER DoNotReset
    Keep $LASTEXITCODE intact after the assertion.
.EXAMPLE
    git status
    Assert-LastExitCodeWasZero
.EXAMPLE
    Assert-LastExitCodeWasZero -DoNotReset
#>
function Assert-LastExitCodeWasZero {
    [CmdletBinding()]
    param(
        [switch] $DoNotReset
    )

    $exitVar = Get-Variable LASTEXITCODE -Scope Global -ErrorAction Ignore

    if (-not $exitVar) {
        return
    }

    $code = $exitVar.Value

    if (-not $DoNotReset) {
        Remove-Variable LASTEXITCODE -Scope Global
    }

    if ($code -ne 0) {
        throw "Last exit code was $code (expected 0)"
    }
}
