<#
.SYNOPSIS
    Asserts that a tool is installed and at the expected version.
.DESCRIPTION
    Combines Assert-Command and Assert-ToolVersion into a single call.
    Looks up the command name from the tool's config in tools.yml.
.PARAMETER Tool
    The tool name as defined in Get-ToolConfig (e.g., 'Python', 'AzCli').
.EXAMPLE
    Assert-Tool 'Python'
#>
function Assert-Tool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Tool
    )

    $config = Get-ToolConfig -Tool $Tool
    Assert-Command $config.Command
    Assert-ToolVersion -Tool $Tool
}
