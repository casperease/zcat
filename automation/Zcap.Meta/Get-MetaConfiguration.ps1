<#
.SYNOPSIS
    Loads and caches the meta configuration from assets/config/meta.yml.
.EXAMPLE
    $config = Get-MetaConfiguration
    $config.Customers
#>
function Get-MetaConfiguration {
    [CmdletBinding()]
    param()

    # Cached for session lifetime. Reset by reimporting (.\importer.ps1).
    if ($script:metaConfigCache) {
        return $script:metaConfigCache
    }

    $configPath = Join-Path $PSScriptRoot 'assets/config/meta.yml'
    Assert-PathExist $configPath

    $config = Get-Content $configPath -Raw | ConvertFrom-Yaml -Ordered
    Assert-MetaConfiguration $config

    Write-Verbose "Loading meta configuration from: $configPath"
    $script:metaConfigCache = $config
    $script:metaConfigCache
}
