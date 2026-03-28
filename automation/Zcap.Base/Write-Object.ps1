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
.PARAMETER ForegroundColor
    Color for the output. Defaults to DarkGray.
.EXAMPLE
    Get-Process | Select-Object -First 3 | Write-Object
.EXAMPLE
    $config | Write-Object -Name 'App config'
.EXAMPLE
    @{ a = 1; b = 2 } | Write-Object
#>
function Write-Object {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [AllowNull()]
        [object] $Object,

        [string] $Name,

        [Alias('Color')]
        [System.ConsoleColor] $ForegroundColor = 'DarkGray'
    )

    process {
        if ($null -eq $Object) {
            Write-InformationColored '[null]' -ForegroundColor $ForegroundColor
            return
        }

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

        if ($Name) {
            Write-InformationColored "--- $Name ---" -ForegroundColor $ForegroundColor
        }
        Write-InformationColored $info -ForegroundColor $ForegroundColor

        # Render based on type
        if ($Object -is [string] -or $Object -is [ValueType]) {
            # Simple: string, int, bool, double, etc.
            Write-InformationColored "$Object" -ForegroundColor $ForegroundColor

        }
        elseif ($Object -is [System.Collections.IDictionary]) {
            # Hashtable, OrderedDictionary — stabilize key order (sort hashtables, preserve ordered), then YAML
            $ordered = ConvertTo-SortedDictionary $Object
            Write-InformationColored ($ordered | ConvertTo-Yaml).TrimEnd() -ForegroundColor $ForegroundColor

        }
        elseif ($Object -is [System.Collections.IEnumerable] -and $Object -isnot [string]) {
            # Arrays and collections
            $items = @($Object)
            $hasComplex = $items | Where-Object {
                $_ -isnot [string] -and $_ -isnot [ValueType]
            } | Select-Object -First 1

            if ($hasComplex) {
                Write-InformationColored ($items | ConvertTo-Yaml).TrimEnd() -ForegroundColor $ForegroundColor
            }
            else {
                foreach ($item in $items) {
                    Write-InformationColored "  $item" -ForegroundColor $ForegroundColor
                }
            }

        }
        else {
            # PSCustomObject, complex .NET objects — YAML
            Write-InformationColored ($Object | ConvertTo-Yaml).TrimEnd() -ForegroundColor $ForegroundColor
        }
    }
}
