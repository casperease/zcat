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

    if (-not $script:toolVersionCache) {
        $script:toolVersionCache = @{}
    }

    if ($script:toolVersionCache[$Tool]) {
        Write-Verbose "Version check cached for $Tool — skipping"
        return
    }

    $config = Get-ToolConfig -Tool $Tool
    # -NoAssert: non-zero exit is handled below — we throw our own descriptive error
    $raw = Invoke-CliCommand $config.VersionCommand -PassThru -NoAssert -Silent 2>$null
    if ($raw -match $config.VersionPattern) {
        $installed = $Matches['ver']
        if (-not $installed.StartsWith($config.Version)) {
            $location = (Get-Command $config.Command).Source
            throw "$Tool version mismatch: expected $($config.Version).x, found $installed at '$location'. Run Install-$Tool or uninstall the conflicting version."
        }
    }
    else {
        throw "$Tool is not functional — '$($config.VersionCommand)' did not return a valid version. Run Install-$Tool."
    }

    Write-Verbose "$Tool version $installed verified"
    $script:toolVersionCache[$Tool] = $true
}
