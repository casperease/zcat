<#
.SYNOPSIS
    Pretty-prints any object to the console with type info and smart formatting.
.DESCRIPTION
    Renders objects differently based on their type:
    - Simple values (string, number, bool): displayed directly
    - Hashtables and ordered dictionaries: key = value pairs
    - Collections/arrays: listed as items, or YAML if elements are complex
    - PSCustomObject and other complex types: YAML
    First line always shows the type name and size where relevant.
.PARAMETER Object
    The object to display. Accepts pipeline input.
.PARAMETER Name
    Optional label displayed above the output.
.PARAMETER NoHeader
    Suppress the type info line and name label. Only the rendered value is shown.
.PARAMETER Depth
    Maximum recursion depth for nested objects. Defaults to 10.
.PARAMETER ForegroundColor
    Color for the output. Defaults to DarkGray.
.EXAMPLE
    Get-Process | Select-Object Name, Id, CPU -First 3 | Write-Object
.EXAMPLE
    $config | Write-Object -Name 'App config'
.EXAMPLE
    @{ a = 1; b = 2 } | Write-Object
#>
function Write-Object {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [object] $Object,

        [string] $Name,

        [switch] $NoHeader,

        [int] $Depth = 10,

        [Alias('Color')]
        [System.ConsoleColor] $ForegroundColor = 'DarkGray'
    )

    process {
        $colorSplat = @{ ForegroundColor = $ForegroundColor }

        Assert-NotNull $Object -ErrorText 'Write-Object received $null — check the caller'

        $type = $Object.GetType()
        $typeName = $type.Name

        # Info line
        $info = switch -Regex ($typeName) {
            'String' { "[String] Length: $($Object.Length)" }
            'Object\[\]' { "[Array] Count: $($Object.Count)" }
            'Hashtable|OrderedDictionary' { "[$typeName] Count: $($Object.Count)" }
            default {
                if ($Object -is [System.Collections.ICollection]) {
                    "[$typeName] Count: $($Object.Count)"
                }
                else {
                    "[$($type.FullName)]"
                }
            }
        }

        if (-not $NoHeader) {
            $headerText = if ($Name) { "$Name — $info" } else { $info }
            Write-Header $headerText @colorSplat
        }

        # Render based on type
        if ($Object -is [string] -or $Object -is [ValueType]) {
            # Simple: string, int, bool, double, etc.
            Write-InformationColored "$Object" -ForegroundColor $ForegroundColor

        }
        elseif ($Object -is [System.Collections.IDictionary]) {
            # Hashtable, OrderedDictionary — stabilize key order (sort hashtables, preserve ordered), then YAML
            $yaml = try {
                $ordered = ConvertTo-SortedDictionary $Object
                ($ordered | ConvertTo-Yaml).TrimEnd()
            }
            catch {
                '[not rendered]'
            }
            Write-InformationColored $yaml -ForegroundColor $ForegroundColor

        }
        elseif ($Object -is [System.Collections.IEnumerable] -and $Object -isnot [string]) {
            # Arrays and collections
            $items = try { @($Object) } catch { $null }

            if ($null -eq $items) {
                Write-InformationColored '[not rendered]' -ForegroundColor $ForegroundColor
                return
            }

            $hasComplex = $items | Where-Object {
                $_ -isnot [string] -and $_ -isnot [ValueType]
            } | Select-Object -First 1

            if ($hasComplex) {
                $yaml = try {
                    $safe = $items | ForEach-Object { ConvertTo-YamlSafe $_ -MaxDepth $Depth }
                    ($safe | ConvertTo-Yaml).TrimEnd()
                }
                catch {
                    '[not rendered]'
                }
                Write-InformationColored $yaml -ForegroundColor $ForegroundColor
            }
            else {
                foreach ($item in $items) {
                    Write-InformationColored "  $item" -ForegroundColor $ForegroundColor
                }
            }

        }
        else {
            # PSCustomObject, complex .NET objects — recursively convert for clean YAML
            $yaml = try {
                $safe = ConvertTo-YamlSafe $Object -MaxDepth $Depth
                ($safe | ConvertTo-Yaml).TrimEnd()
            }
            catch {
                '[not rendered]'
            }
            Write-InformationColored $yaml -ForegroundColor $ForegroundColor
        }
    }
}
