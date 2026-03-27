<#
.SYNOPSIS
    Asserts that a value is boolean $true.
.PARAMETER Value
    The value to test. Must be exactly [bool] $true.
.PARAMETER ErrorText
    Custom error message. Defaults to file and line info.
.EXAMPLE
    Assert-True $result
.EXAMPLE
    Assert-True ($x -eq 1) -ErrorText 'x must equal 1'
#>
function Assert-True {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object] $Value,

        [string] $ErrorText
    )

    if (-not (($Value -is [bool]) -and $Value)) {
        $message = if ($ErrorText) { $ErrorText } else {
            "Assertion failed: expected `$true — {0}, line {1}" -f $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber
        }
        throw $message
    }
}
