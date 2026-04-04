<#
.SYNOPSIS
    Recursively converts an object into a YAML-safe structure of ordered
    dictionaries, arrays, and scalar values.
.DESCRIPTION
    Used by Write-Object to produce clean YAML output for nested objects.
    Walks PSCustomObject, IDictionary, and IEnumerable types, converting
    each level into ordered hashtables or arrays that ConvertTo-Yaml can
    serialize without falling back to ToString().
#>
function ConvertTo-YamlSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        $Value,

        [int] $MaxDepth = 10,

        [int] $Depth = 0
    )

    if ($null -eq $Value) { return $null }
    if ($Value -is [string] -or $Value -is [ValueType]) { return $Value }
    if ($Depth -ge $MaxDepth) { return "$Value" }

    if ($Value -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $result[$key] = ConvertTo-YamlSafe -Value $Value[$key] -MaxDepth $MaxDepth -Depth ($Depth + 1)
        }
        return $result
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $list = foreach ($item in $Value) {
            ConvertTo-YamlSafe -Value $item -MaxDepth $MaxDepth -Depth ($Depth + 1)
        }
        return @($list)
    }

    # PSCustomObject or other complex types
    $bag = [ordered]@{}
    foreach ($p in $Value.PSObject.Properties) {
        $v = try { $p.Value } catch { $null }
        $bag[$p.Name] = ConvertTo-YamlSafe -Value $v -MaxDepth $MaxDepth -Depth ($Depth + 1)
    }
    return $bag
}
