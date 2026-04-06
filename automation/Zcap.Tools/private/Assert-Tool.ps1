<#
.SYNOPSIS
    Asserts that a tool is installed and at the expected version.
.DESCRIPTION
    Checks that the tool's command is on PATH and that its version
    matches the locked version in tools.yml. Does NOT check DependsOn —
    those are install-time dependencies, not runtime requirements.
.PARAMETER Tool
    The tool name as defined in Get-ToolConfig (e.g., 'Python', 'AzCli').
.EXAMPLE
    Assert-Tool 'Python'
.EXAMPLE
    Assert-Tool 'Poetry'
#>
function Assert-Tool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Tool
    )

    $config = Get-ToolConfig -Tool $Tool

    Assert-Command $config.Command -ErrorText "$Tool is not installed ($($config.Command) not found on PATH). Run Install-$Tool."
    Assert-ToolVersion -Tool $Tool
}
