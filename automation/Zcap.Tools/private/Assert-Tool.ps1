<#
.SYNOPSIS
    Asserts that a tool is installed and at the expected version.
.DESCRIPTION
    Checks DependsOn first (from tools.yml), then Assert-Command and
    Assert-ToolVersion. Produces "Poetry requires Python" instead of
    "Could not parse Poetry version" when a dependency is missing.
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

    # Check dependency FIRST — produce actionable error naming the root cause
    if ($config.DependsOn) {
        $depConfig = Get-ToolConfig -Tool $config.DependsOn
        Assert-Command $depConfig.Command -ErrorText "$Tool requires $($config.DependsOn) ($($depConfig.Command)) — run Install-$($config.DependsOn)"
        Assert-ToolVersion -Tool $config.DependsOn
    }

    Assert-Command $config.Command
    Assert-ToolVersion -Tool $Tool
}
