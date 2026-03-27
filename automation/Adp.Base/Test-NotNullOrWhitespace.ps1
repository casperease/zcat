<#
.SYNOPSIS
    Tests whether a value is not null, empty, or whitespace.
.PARAMETER Value
    The value to test.
.EXAMPLE
    Test-NotNullOrWhitespace 'hello'
    # True
.EXAMPLE
    Test-NotNullOrWhitespace '  '
    # False
#>
function Test-NotNullOrWhitespace {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $Value
    )

    -not [string]::IsNullOrWhiteSpace($Value)
}
