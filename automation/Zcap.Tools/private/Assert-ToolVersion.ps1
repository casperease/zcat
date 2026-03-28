<#
.SYNOPSIS
    Asserts the installed version of a tool matches its locked version.
.DESCRIPTION
    Checks once per session and caches the result. Subsequent calls
    for the same tool return immediately.
.PARAMETER Tool
    The tool name as defined in Get-ToolConfig.
#>
function Assert-ToolVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Tool
    )

    if (-not $script:ToolVersionCache) {
        $script:ToolVersionCache = @{}
    }

    if ($script:ToolVersionCache[$Tool]) { return }

    $config = Get-ToolConfig -Tool $Tool
    $raw = Invoke-CliCommand $config.VersionCommand -PassThru -NoAssert -Silent
    if ($raw -match $config.VersionPattern) {
        $installed = $Matches['ver']
        if (-not $installed.StartsWith($config.Version)) {
            $location = (Get-Command $config.Command).Source
            throw "$Tool version mismatch: expected $($config.Version).x, found $installed at '$location'. Run Install-$Tool or uninstall the conflicting version."
        }
    }
    else {
        throw "Could not parse $Tool version from: $raw"
    }

    $script:ToolVersionCache[$Tool] = $true
}
