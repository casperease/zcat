<#
.SYNOPSIS
    Provisions the development environment with all required tools.
.DESCRIPTION
    Installs all locked tool versions. Idempotent — safe to run
    repeatedly. Skips tools that are already installed at the correct
    version.
.PARAMETER Force
    Replace existing installations that are at the wrong version.
.EXAMPLE
    Install-DevBox
.EXAMPLE
    Install-DevBox -Force
#>
function Install-DevBox {
    [CmdletBinding()]
    param(
        [switch] $Force
    )

    Install-Python -Force:$Force
    Install-Poetry
    Install-Dotnet -Force:$Force
    Install-AzCli -Force:$Force
}
