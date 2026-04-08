<#
.SYNOPSIS
    Asserts that a filesystem path exists.
.PARAMETER Path
    The path to test.
.PARAMETER PathType
    The kind of path to require: Any (default), Container, or Leaf.
.EXAMPLE
    Assert-PathExist './config.json'
.EXAMPLE
    Assert-PathExist './src' -PathType Container
#>
function Assert-PathExist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Path,

        [ValidateSet('Any', 'Container', 'Leaf')]
        [string] $PathType = 'Any',

        [string] $ErrorText
    )

    if (-not (Test-Path -Path $Path -PathType $PathType)) {
        throw ($ErrorText ?? "Path does not exist: $Path")
    }
}
