Describe 'ConvertTo-YamlSafe' {
    BeforeAll {
        $mod = Get-Module Zcat.Utils
    }

    It 'passes through null' {
        $result = & $mod { ConvertTo-YamlSafe -Value $null }
        $result | Should -BeNullOrEmpty
    }

    It 'passes through strings' {
        $result = & $mod { ConvertTo-YamlSafe -Value 'hello' }
        $result | Should -Be 'hello'
    }

    It 'passes through value types' {
        (& $mod { ConvertTo-YamlSafe -Value 42 }) | Should -Be 42
        (& $mod { ConvertTo-YamlSafe -Value $true }) | Should -BeTrue
        (& $mod { ConvertTo-YamlSafe -Value 3.14 }) | Should -Be 3.14
    }

    It 'converts PSCustomObject to ordered dictionary' {
        $result = & $mod { ConvertTo-YamlSafe -Value ([PSCustomObject]@{ A = 1; B = 'two' }) }

        $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        $result['A'] | Should -Be 1
        $result['B'] | Should -Be 'two'
    }

    It 'converts hashtable to ordered dictionary' {
        $result = & $mod { ConvertTo-YamlSafe -Value @{ X = 10 } }

        $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        $result['X'] | Should -Be 10
    }

    It 'converts arrays and preserves items' {
        $result = & $mod { ConvertTo-YamlSafe -Value @('a', 'b', 'c') }

        $result | Should -HaveCount 3
        $result[0] | Should -Be 'a'
    }

    It 'recurses nested PSCustomObjects' {
        $obj = [PSCustomObject]@{
            L1 = [PSCustomObject]@{
                L2 = [PSCustomObject]@{
                    L3 = 'deep'
                }
            }
        }

        $result = & $mod { ConvertTo-YamlSafe -Value $args[0] } $obj

        $result['L1'] | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        $result['L1']['L2'] | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        $result['L1']['L2']['L3'] | Should -Be 'deep'
    }

    It 'recurses arrays of objects' {
        $arr = @(
            [PSCustomObject]@{ Name = 'a' }
            [PSCustomObject]@{ Name = 'b' }
        )

        $result = & $mod { ConvertTo-YamlSafe -Value $args[0] } $arr

        $result | Should -HaveCount 2
        $result[0]['Name'] | Should -Be 'a'
        $result[1]['Name'] | Should -Be 'b'
    }

    It 'recurses nested dictionaries' {
        $ht = @{
            Outer = @{
                Inner = 'val'
            }
        }

        $result = & $mod { ConvertTo-YamlSafe -Value $args[0] } $ht

        $result['Outer'] | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        $result['Outer']['Inner'] | Should -Be 'val'
    }

    It 'handles mixed-type arrays with nested objects' {
        $arr = @(
            'text'
            42
            [PSCustomObject]@{
                Inner = [PSCustomObject]@{
                    Deep = [PSCustomObject]@{ Leaf = $true }
                }
            }
        )

        $result = & $mod { ConvertTo-YamlSafe -Value $args[0] } $arr

        $result[0] | Should -Be 'text'
        $result[1] | Should -Be 42
        $result[2]['Inner']['Deep']['Leaf'] | Should -BeTrue
    }

    It 'respects MaxDepth and stringifies beyond limit' {
        $obj = [PSCustomObject]@{
            A = [PSCustomObject]@{
                B = [PSCustomObject]@{
                    C = 'too deep'
                }
            }
        }

        $result = & $mod { ConvertTo-YamlSafe -Value $args[0] -MaxDepth 2 } $obj

        $result['A']['B'] | Should -BeOfType [string]
    }

    It 'produces clean YAML without @{ artifacts' {
        $obj = [PSCustomObject]@{
            Name = 'svc'
            Health = [PSCustomObject]@{
                Status = 'OK'
                Checks = [PSCustomObject]@{
                    DB = 'OK'
                    Cache = 'Degraded'
                }
            }
        }

        $yaml = (& $mod { ConvertTo-YamlSafe $args[0] | ConvertTo-Yaml } $obj).TrimEnd()

        $yaml | Should -Match 'Name: svc'
        $yaml | Should -Match 'Status: OK'
        $yaml | Should -Match 'DB: OK'
        $yaml | Should -Match 'Cache: Degraded'
        $yaml | Should -Not -Match '@\{'
    }
}
