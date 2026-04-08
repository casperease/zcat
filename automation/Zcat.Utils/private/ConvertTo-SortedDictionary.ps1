<#
.SYNOPSIS
    Recursively converts dictionaries to ordered form for stable output.
.DESCRIPTION
    OrderedDictionaries keep their original key order.
    Plain Hashtables get their keys sorted alphabetically.
    Nested dictionaries are processed recursively.
.PARAMETER Dictionary
    The dictionary to process.
#>
function ConvertTo-SortedDictionary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [System.Collections.IDictionary] $Dictionary
    )

    $alreadyOrdered = $Dictionary -is [System.Collections.Specialized.OrderedDictionary]
    $keys = if ($alreadyOrdered) { $Dictionary.Keys } else { $Dictionary.Keys | Sort-Object }

    $result = [ordered]@{}
    foreach ($key in $keys) {
        $value = $Dictionary[$key]
        if ($value -is [System.Collections.IDictionary]) {
            $result[$key] = ConvertTo-SortedDictionary $value
        }
        else {
            $result[$key] = $value
        }
    }
    $result
}
