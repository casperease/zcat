<#
.SYNOPSIS
    Asserts that a value is not null, empty, or whitespace.
.PARAMETER Value
    The value to test. Evaluated via [string]::IsNullOrWhiteSpace().
.PARAMETER ErrorText
    Custom error message. Defaults to file and line info.
.EXAMPLE
    Assert-NotNullOrWhitespace $name
#>
function Assert-NotNullOrWhitespace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object] $Value,

        [string] $ErrorText
    )

    if (-not (Test-NotNullOrWhitespace $Value)) {
        $message = if ($ErrorText) { $ErrorText } else {
            "Assertion failed: value was null or whitespace — {0}, line {1}" -f $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber
        }
        throw $message
    }
}
