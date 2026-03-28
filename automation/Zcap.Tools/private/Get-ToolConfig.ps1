<#
.SYNOPSIS
    Returns the locked configuration for a CLI tool.
.DESCRIPTION
    Reads tool definitions from config/tools.yml. Caches the parsed
    YAML for the lifetime of the session.
.PARAMETER Tool
    The tool name (e.g., 'Python').
.EXAMPLE
    $config = Get-ToolConfig -Tool 'Python'
#>
function Get-ToolConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Tool
    )

    if (-not $script:ToolConfigCache) {
        $configPath = Join-Path $PSScriptRoot '../config/tools.yml'
        Assert-PathExist $configPath
        $script:ToolConfigCache = Get-Content $configPath -Raw | ConvertFrom-Yaml
    }

    $config = $script:ToolConfigCache[$Tool]
    if (-not $config) {
        throw "Unknown tool '$Tool'. Known tools: $($script:ToolConfigCache.Keys -join ', ')"
    }

    $config
}
