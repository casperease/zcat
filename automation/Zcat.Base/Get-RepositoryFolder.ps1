<#
.SYNOPSIS
    Returns the full path to a folder relative to the repository root.
.PARAMETER Path
    Relative path from the repository root.
.EXAMPLE
    Get-RepositoryFolder 'automation/PseCore'
#>
function Get-RepositoryFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Path
    )

    Join-Path $env:RepositoryRoot $Path
}
