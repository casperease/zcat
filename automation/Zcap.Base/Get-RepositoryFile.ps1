<#
.SYNOPSIS
    Returns the full path to a file relative to the repository root.
.PARAMETER Path
    Relative path from the repository root.
.EXAMPLE
    Get-RepositoryFile 'importer.ps1'
#>
function Get-RepositoryFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Path
    )

    Join-Path $env:RepositoryRoot $Path
}
