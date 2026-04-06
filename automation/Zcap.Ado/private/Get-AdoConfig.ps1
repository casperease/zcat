<#
.SYNOPSIS
    Returns the ADO configuration from assets/config/ado.yml.
.DESCRIPTION
    Reads Organization and Project from the config file and caches
    the result for the session lifetime. Used as the default source
    for ADO API functions when env vars and parameters are not set.
.EXAMPLE
    $config = Get-AdoConfig
    $config.Organization
    $config.Project
#>
function Get-AdoConfig {
    [CmdletBinding()]
    param()

    # Cached for session lifetime. Reset by reimporting (.\importer.ps1).
    if ($script:adoConfigCache) {
        return $script:adoConfigCache
    }

    $configPath = Join-Path $PSScriptRoot '../assets/config/ado.yml'
    Assert-PathExist $configPath

    Write-Verbose "Loading ADO config from: $configPath"
    $script:adoConfigCache = Get-Content $configPath -Raw | ConvertFrom-Yaml

    $script:adoConfigCache
}
