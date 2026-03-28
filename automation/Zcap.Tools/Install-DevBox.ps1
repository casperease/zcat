<#
.SYNOPSIS
    Provisions the development environment with all required tools.
.DESCRIPTION
    Installs all locked tool versions. Idempotent — safe to run
    repeatedly. Skips tools that are already installed at the correct
    version.
.EXAMPLE
    Install-DevBox
#>
function Install-DevBox {
    [CmdletBinding()]
    param()

    Install-Python
    Install-Poetry
    Install-Dotnet
    Install-AzCli
}
