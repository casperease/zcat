<#
.SYNOPSIS
    Asserts that an object is a specific .NET type.
.PARAMETER Object
    The object whose type to check.
.PARAMETER TypeFullName
    The expected full type name (e.g. 'System.String').
.EXAMPLE
    Assert-TypeIs $value 'System.Int32'
#>
function Assert-TypeIs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        $Object,

        [Parameter(Mandatory, Position = 1)]
        [string] $TypeFullName
    )

    if ($Object.GetType().FullName -ne $TypeFullName) {
        throw "Object is not a $TypeFullName (actual: $($Object.GetType().FullName))"
    }
}
