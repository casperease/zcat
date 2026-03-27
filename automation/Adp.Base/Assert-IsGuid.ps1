<#
.SYNOPSIS
    Asserts that a string is a valid GUID.
.PARAMETER ObjectGuid
    The string to validate as a GUID.
.EXAMPLE
    Assert-IsGuid 'd3b07384-d9a0-4c9b-8a0d-6e5c7a8b9c0d'
#>
function Assert-IsGuid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $ObjectGuid
    )

    if (-not (Test-IsGuid $ObjectGuid)) {
        throw "'$ObjectGuid' is not a valid GUID"
    }
}
