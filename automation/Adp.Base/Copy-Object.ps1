<#
.SYNOPSIS
    Deep clones a PowerShell object.
.DESCRIPTION
    Recursively copies hashtables, ordered dictionaries, PSCustomObjects,
    arrays, and lists. Value types and strings are returned as-is (immutable
    or copied by value). Unknown reference types are returned by reference.

    PSCustomObject cloning only copies NoteProperties. Use -AcceptWarnings
    to suppress the warning about this limitation.

    Does not use BinaryFormatter or any serialization-based approach.
.PARAMETER InputObject
    The object to deep clone.
.PARAMETER AcceptWarnings
    Suppresses warnings about PSCustomObject cloning limitations.
.EXAMPLE
    $clone = Copy-Object $original
.EXAMPLE
    $clone = Copy-Object $original -AcceptWarnings
#>
function Copy-Object {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [AllowNull()]
        $InputObject,

        [switch] $AcceptWarnings
    )

    begin {
        $warned = $false

        function Clone($obj) {
            # Null
            if ($null -eq $obj) { return $null }

            # Value types (int, bool, datetime, enum, etc.) — copied by value
            if ($obj.GetType().IsValueType) { return $obj }

            # Strings — immutable, safe to share
            if ($obj -is [string]) { return $obj }

            # Ordered dictionary — must check before IDictionary
            if ($obj -is [System.Collections.Specialized.OrderedDictionary]) {
                $c = [ordered]@{}
                foreach ($key in $obj.Keys) {
                    $c[$key] = Clone $obj[$key]
                }
                return $c
            }

            # Hashtable / other dictionaries
            if ($obj -is [System.Collections.IDictionary]) {
                $c = @{}
                foreach ($key in $obj.Keys) {
                    $c[$key] = Clone $obj[$key]
                }
                return $c
            }

            # PSCustomObject
            if ($obj.PSObject.Properties.Count -gt 0 -and
                $obj.GetType().Name -eq 'PSCustomObject') {
                if (-not $AcceptWarnings -and -not $warned) {
                    Write-Warning 'Only copying note properties, use -AcceptWarnings to suppress this'
                    Set-Variable warned $true -Scope 1
                }
                $c = [PSCustomObject]@{}
                foreach ($prop in $obj.PSObject.Properties) {
                    $c | Add-Member -NotePropertyName $prop.Name -NotePropertyValue (Clone $prop.Value)
                }
                return $c
            }

            # Arrays and lists
            if ($obj -is [System.Collections.IList]) {
                $c = [System.Collections.Generic.List[object]]::new($obj.Count)
                foreach ($item in $obj) {
                    $c.Add((Clone $item))
                }
                if ($obj -is [array]) {
                    return @(, $c.ToArray())
                }
                return $c
            }

            # Fallback: return reference for unknown types
            $obj
        }
    }

    process {
        Clone $InputObject
    }
}
