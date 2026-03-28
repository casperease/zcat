<#
.SYNOPSIS
    Loads and caches the meta configuration from config/meta.yml.
.EXAMPLE
    $config = Get-MetaConfiguration
    $config.Customers
#>
function Get-MetaConfiguration {
    [CmdletBinding()]
    param()

    if ($script:MetaConfigCache) {
        return $script:MetaConfigCache
    }

    $configPath = Join-Path $PSScriptRoot 'config/meta.yml'
    Assert-PathExist $configPath

    $config = Get-Content $configPath -Raw | ConvertFrom-Yaml -Ordered
    Assert-MetaConfiguration $config

    Write-Verbose "Loading meta configuration from: $configPath"
    $script:MetaConfigCache = $config
    $script:MetaConfigCache
}
