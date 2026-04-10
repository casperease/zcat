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
    if ($Depth -ge $MaxDepth) { try { return "$Value" } catch { return '[not rendered]' } }

    if ($Value -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $result[$key] = try {
                ConvertTo-YamlSafe -Value $Value[$key] -MaxDepth $MaxDepth -Depth ($Depth + 1)
            }
            catch {
                '[not rendered]'
            }
        }
        return $result
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $list = try {
            foreach ($item in $Value) {
                try {
                    ConvertTo-YamlSafe -Value $item -MaxDepth $MaxDepth -Depth ($Depth + 1)
                }
                catch {
                    '[not rendered]'
                }
            }
        }
        catch {
            return '[not rendered]'
        }
        return @($list)
    }

    # PSCustomObject or other complex types
    $bag = [ordered]@{}
    $properties = try { @($Value.PSObject.Properties) } catch { $null }
    if ($null -eq $properties) { return '[not rendered]' }

    foreach ($p in $properties) {
        $name = try { $p.Name } catch { continue }
        $v = if ($p -is [System.Management.Automation.PSScriptProperty] -and $null -ne $p.GetterScript) {
            try { $p.GetterScript.InvokeReturnAsIs() } catch { '[not rendered]' }
        }
        else {
            try { $p.Value } catch { '[not rendered]' }
        }
        $bag[$name] = try {
            ConvertTo-YamlSafe -Value $v -MaxDepth $MaxDepth -Depth ($Depth + 1)
        }
        catch {
            '[not rendered]'
        }
    }
    return $bag
}
