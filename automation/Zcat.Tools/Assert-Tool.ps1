<#
.SYNOPSIS
    Asserts that a tool is installed and at the expected version.
.DESCRIPTION
    Checks that the tool's command is on PATH and that its version
    matches the locked version in tools.yml. Does NOT check DependsOn —
    those are install-time dependencies, not runtime requirements.
.PARAMETER Tool
    The tool name as defined in Get-ToolConfig (e.g., 'Python', 'AzCli').
.PARAMETER SkipVersionCheck
    Only assert the tool is on PATH. Skip the version match.
    Use for operations that need presence but not a specific version
    (e.g., uninstalling).
.EXAMPLE
    Assert-Tool 'Python'
.EXAMPLE
    Assert-Tool 'Poetry'
#>
function Assert-Tool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Tool,
        [switch] $SkipVersionCheck
    )

    $config = Get-ToolConfig -Tool $Tool

    Assert-Command $config.Command -ErrorText "$Tool is not installed ($($config.Command) not found on PATH). Run Install-$Tool."

    if (-not $SkipVersionCheck) {
        Assert-ToolVersion -Tool $Tool
    }
}
