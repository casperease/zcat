<#
.SYNOPSIS
    Asserts that an object has a named property.
.PARAMETER Object
    The object to inspect.
.PARAMETER PropertyName
    The property name that must exist on the object.
.EXAMPLE
    Assert-HaveProperty $response 'StatusCode'
#>
function Assert-HaveProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [object] $Object,

        [Parameter(Mandatory, Position = 1)]
        [string] $PropertyName
    )

    if (-not (Test-HaveProperty $Object $PropertyName)) {
        throw "Object does not have property '$PropertyName'"
    }
}
