<#
.SYNOPSIS
    Asserts that a value is $null.
.PARAMETER Value
    The value to test. Must be exactly $null.
.PARAMETER ErrorText
    Custom error message. Defaults to file and line info.
.EXAMPLE
    Assert-Null $result
#>
function Assert-Null {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object] $Value,

        [string] $ErrorText
    )

    if ($null -ne $Value) {
        $message = if ($ErrorText) { $ErrorText } else {
            "Assertion failed: expected `$null — {0}, line {1}" -f $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber
        }
        throw $message
    }
}
