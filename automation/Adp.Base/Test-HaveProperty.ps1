<#
.SYNOPSIS
    Tests whether an object has a specific property.
.PARAMETER Object
    The object to inspect.
.PARAMETER PropertyName
    The property name to look for.
.EXAMPLE
    Test-HaveProperty $obj 'Name'
#>
function Test-HaveProperty {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [object] $Object,

        [Parameter(Mandatory, Position = 1)]
        [string] $PropertyName
    )

    $PropertyName -in $Object.PSObject.Properties.Name
}
