<#
.SYNOPSIS
    Tests whether a tool is installed at the expected version.
.DESCRIPTION
    Returns $true if the tool's command exists on PATH, its version
    command produces parseable output, AND the installed version matches
    the locked version in tools.yml. Returns $false for missing tools,
    Windows Store stubs, broken installations, and version mismatches.
.PARAMETER Tool
    The tool name as defined in Get-ToolConfig.
.PARAMETER SkipVersionCheck
    Only test the tool is on PATH and functional. Skip the version match.
    Use for operations that need presence but not a specific version
    (e.g., uninstalling).
.EXAMPLE
    Test-Tool 'Python'
.EXAMPLE
    Test-Tool 'Python' -SkipVersionCheck
#>
function Test-Tool {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Tool,
        [switch] $SkipVersionCheck
    )

    $config = Get-ToolConfig -Tool $Tool

    if (-not (Test-Command $config.Command)) { return $false }

    $installed = Get-ToolVersion -Config $config
    if ($null -eq $installed) { return $false }

    if (-not $SkipVersionCheck) {
        return $installed.StartsWith($config.Version)
    }

    $true
}
