<#
.SYNOPSIS
    Uninstalls the .NET SDK via the platform package manager.
.PARAMETER Version
    .NET SDK version to uninstall. Defaults to the locked version in Get-ToolConfig.
.EXAMPLE
    Uninstall-Dotnet
.EXAMPLE
    Uninstall-Dotnet -Version '10.0'
#>
function Uninstall-Dotnet {
    [CmdletBinding()]
    param(
        [string] $Version
    )

    Uninstall-Tool -Tool 'Dotnet' -Version $Version
}
