<#
.SYNOPSIS
    Installs PySpark via pip.
.DESCRIPTION
    Requires Python (implicit via pip) and Java (DependsOn in tools.yml).
    Assert-Tool checks Java before PySpark is used.
.PARAMETER Version
    PySpark version to install. Defaults to the locked version in Get-ToolConfig.
.EXAMPLE
    Install-PySpark
.EXAMPLE
    Install-PySpark -Version '3.5'
#>
function Install-PySpark {
    [CmdletBinding()]
    param(
        [string] $Version,
        [switch] $Force
    )

    Install-PipTool -Tool 'PySpark' -Version $Version -Force:$Force
}
