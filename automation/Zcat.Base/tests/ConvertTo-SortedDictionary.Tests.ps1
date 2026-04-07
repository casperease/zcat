Describe 'ConvertTo-SortedDictionary' {
    It 'preserves order of OrderedDictionary' {
        $input = [ordered]@{ z = 1; a = 2; m = 3 }
        $result = & (Get-Module Zcat.Base) { ConvertTo-SortedDictionary $args[0] } $input
        @($result.Keys) | Should -Be @('z', 'a', 'm')
    }

    It 'sorts keys of plain Hashtable' {
        $input = @{ z = 1; a = 2; m = 3 }
        $result = & (Get-Module Zcat.Base) { ConvertTo-SortedDictionary $args[0] } $input
        @($result.Keys) | Should -Be @('a', 'm', 'z')
    }

    It 'recursively processes nested dictionaries' {
        $input = @{ b = @{ z = 1; a = 2 }; a = 'leaf' }
        $result = & (Get-Module Zcat.Base) { ConvertTo-SortedDictionary $args[0] } $input
        @($result.Keys) | Should -Be @('a', 'b')
        @($result.b.Keys) | Should -Be @('a', 'z')
    }

    It 'returns an OrderedDictionary' {
        $input = @{ a = 1 }
        $result = & (Get-Module Zcat.Base) { ConvertTo-SortedDictionary $args[0] } $input
        $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
    }
}
