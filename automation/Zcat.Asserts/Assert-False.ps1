<#
.SYNOPSIS
    Asserts that a value is boolean $false.
.PARAMETER Value
    The value to test. Must be exactly [bool] $false.
.PARAMETER ErrorText
    Custom error message. Defaults to file and line info.
.EXAMPLE
    Assert-False $result
.EXAMPLE
    Assert-False ($x -eq 1) -ErrorText 'x should not equal 1'
#>
function Assert-False {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object] $Value,

        [string] $ErrorText
    )

    if (-not (($Value -is [bool]) -and (-not $Value))) {
        $message = if ($ErrorText) { $ErrorText } else {
            "Assertion failed: expected `$false — {0}, line {1}" -f $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber
        }
        throw $message
    }
}
