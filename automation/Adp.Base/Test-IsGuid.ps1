<#
.SYNOPSIS
    Tests whether a string is a valid GUID.
.PARAMETER ObjectGuid
    The string to validate as a GUID.
.EXAMPLE
    Test-IsGuid 'd3b07384-d9a0-4c9b-8a0d-6e7b8f3a1c2d'
#>
function Test-IsGuid {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $ObjectGuid
    )

    [guid]::TryParse($ObjectGuid, [ref][guid]::Empty)
}
