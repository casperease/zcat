<#
.SYNOPSIS
    Runs a tool's version command and extracts the installed version string.
.DESCRIPTION
    Executes the VersionCommand from tools.yml, matches against
    VersionPattern, and returns the captured version string.
    Returns $null if the command fails or the pattern does not match.
    Uses .Full (stdout + stderr merged) to catch tools like java that
    write version info to stderr.
.PARAMETER Config
    The tool configuration hashtable from Get-ToolConfig.
.EXAMPLE
    $config = Get-ToolConfig -Tool 'Python'
    $version = Get-ToolVersion -Config $config
    # Returns '3.11.9' or $null
#>
function Get-ToolVersion {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    $result = Invoke-Executable $Config.VersionCommand -PassThru -NoAssert -Silent

    if ($result.Full -match $Config.VersionPattern) {
        return $Matches['ver']
    }

    return $null
}
