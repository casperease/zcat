<#
.SYNOPSIS
    Installs the .NET SDK via the platform package manager.
.PARAMETER Version
    .NET SDK version to install. Defaults to the locked version in Get-ToolConfig.
.EXAMPLE
    Install-Dotnet
.EXAMPLE
    Install-Dotnet -Version '10.0'
#>
function Install-Dotnet {
    [CmdletBinding()]
    param(
        [string] $Version
    )

    Install-Tool -Tool 'Dotnet' -Version $Version
}
