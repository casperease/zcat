<#
.SYNOPSIS
    Returns the whitelisted environment variable names for pipeline diagnostics.
.DESCRIPTION
    Reads the list from assets/config/pipeline-env.yml and caches it.
#>
function Get-AdoPipelineEnvWhitelist {
    [CmdletBinding()]
    param()

    # Cached for session lifetime. Reset by reimporting (.\importer.ps1).
    if ($script:pipelineEnvWhitelistCache) {
        return $script:pipelineEnvWhitelistCache
    }

    $configPath = Join-Path $PSScriptRoot '../assets/config/pipeline-env.yml'
    Assert-PathExist $configPath

    Write-Verbose "Loading pipeline env whitelist from: $configPath"
    $script:pipelineEnvWhitelistCache = Get-Content $configPath -Raw | ConvertFrom-Yaml

    $script:pipelineEnvWhitelistCache
}
