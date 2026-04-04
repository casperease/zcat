<#
.SYNOPSIS
    Flattens a nested object into an ordered dictionary of dot-notation key/value pairs.
.DESCRIPTION
    Recursively walks a PSCustomObject (e.g. parsed JSON/YAML configuration)
    and returns an OrderedDictionary where each key is the full dot-separated
    path to a leaf property and each value is the leaf value.

    Non-leaf nodes (objects, dictionaries, arrays) are expanded, not included.
    Null values are stored as empty strings.

    Supports pipeline input for batch processing.
.PARAMETER InputObject
    One or more objects to flatten.
.PARAMETER MaxDepth
    Maximum recursion depth. Defaults to 10.
.EXAMPLE
    $config = Get-Content config.json | ConvertFrom-Json
    $flat = $config | ConvertTo-FlatSettingSet
    $flat.Keys | ForEach-Object { "$_ = $($flat[$_])" }
    # app.name = myapp
    # app.settings.timeout = 30
.EXAMPLE
    $flat = ConvertTo-FlatSettingSet $config
    foreach ($key in $flat.Keys) {
        Assert-False ($flat[$key] -eq 'UNDEFINED') "Key '$key' is not defined"
    }
#>
function ConvertTo-FlatSettingSet {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [PSObject[]] $InputObject,

        [int] $MaxDepth = 10
    )

    process {
        foreach ($object in $InputObject) {
            $settings = [ordered]@{}
            Expand-ObjectProperties -Value $object -Target $settings -MaxDepth $MaxDepth
            $settings
        }
    }
}
