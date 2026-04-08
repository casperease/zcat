<#
.SYNOPSIS
    Recursively flattens a nested object into dot-notation key/value pairs.
.DESCRIPTION
    Walks PSCustomObject, IDictionary, and array structures, building
    dot-separated paths for each leaf value and adding them to the
    supplied OrderedDictionary.  Arrays use [index] notation.
    Used internally by ConvertTo-FlatSettingSet.
#>
function Expand-ObjectProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory)]
        [System.Collections.Specialized.OrderedDictionary] $Target,

        [string] $Prefix,

        [int] $MaxDepth = 10,

        [int] $Depth = 0
    )

    if ($Depth -ge $MaxDepth) { return }

    if ($null -eq $Value) {
        if ($Prefix) { $Target[$Prefix] = '' }
        return
    }

    if ($Value -is [PSCustomObject]) {
        foreach ($property in $Value.PSObject.Properties) {
            $path = if ($Prefix) { "$Prefix.$($property.Name)" } else { $property.Name }
            Expand-ObjectProperties -Value $property.Value -Target $Target -Prefix $path -MaxDepth $MaxDepth -Depth ($Depth + 1)
        }
        return
    }

    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            $path = if ($Prefix) { "$Prefix.$key" } else { $key }
            Expand-ObjectProperties -Value $Value[$key] -Target $Target -Prefix $path -MaxDepth $MaxDepth -Depth ($Depth + 1)
        }
        return
    }

    if ($Value -is [array]) {
        $index = 0
        foreach ($item in $Value) {
            $path = if ($Prefix) { "$Prefix[$index]" } else { "[$index]" }
            Expand-ObjectProperties -Value $item -Target $Target -Prefix $path -MaxDepth $MaxDepth -Depth ($Depth + 1)
            $index++
        }
        return
    }

    if ($Prefix) {
        $Target[$Prefix] = $Value
    }
}
