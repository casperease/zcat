<#
.SYNOPSIS
    Asserts that a value is not $null.
.PARAMETER Value
    The value to test. Must not be $null.
.PARAMETER ErrorText
    Custom error message. Defaults to file and line info.
.EXAMPLE
    Assert-NotNull $result
.EXAMPLE
    Assert-NotNull $release -ErrorText 'GitHub API returned null'
#>
function Assert-NotNull {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object] $Value,

        [string] $ErrorText
    )

    if ($null -eq $Value) {
        $message = if ($ErrorText) { $ErrorText } else {
            "Assertion failed: value was null — {0}, line {1}" -f $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber
        }
        throw $message
    }
}
