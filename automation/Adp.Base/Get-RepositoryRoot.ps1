<#
.SYNOPSIS
    Returns the repository root path.
.DESCRIPTION
    Returns the value of $env:RepositoryRoot set by importer.ps1.
.EXAMPLE
    Get-RepositoryRoot
#>
function Get-RepositoryRoot {
    [CmdletBinding()]
    param()

    $env:RepositoryRoot
}
