<#
.SYNOPSIS
    Tests whether a tool is installed and functional.
.DESCRIPTION
    Returns $true if the tool's command exists on PATH AND its version
    command produces parseable output. Returns $false for missing tools,
    Windows Store stubs, and broken installations.
.PARAMETER Tool
    The tool name as defined in Get-ToolConfig.
.EXAMPLE
    Test-Tool 'Python'
#>
function Test-Tool {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Tool
    )

    $config = Get-ToolConfig -Tool $Tool

    if (-not (Test-Command $config.Command)) { return $false }

    $null -ne (Get-ToolVersion -Config $config)
}
