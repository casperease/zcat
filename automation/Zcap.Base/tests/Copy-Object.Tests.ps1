Describe 'Copy-Object' {

    Context 'null and scalar values' {
        It 'handles null' {
            $clone = Copy-Object $null
            $clone | Should -BeNullOrEmpty
        }

        It 'passes through string' {
            Copy-Object 'hello' | Should -Be 'hello'
        }

        It 'passes through empty string' {
            Copy-Object '' | Should -Be ''
        }

        It 'passes through integer' {
            Copy-Object 42 | Should -Be 42
        }

        It 'passes through zero' {
            Copy-Object 0 | Should -Be 0
        }

        It 'passes through negative integer' {
            Copy-Object -1 | Should -Be -1
        }

        It 'passes through double' {
            Copy-Object 3.14 | Should -Be 3.14
        }

        It 'passes through boolean true' {
            Copy-Object $true | Should -BeTrue
        }

        It 'passes through boolean false' {
            Copy-Object $false | Should -BeFalse
        }

        It 'passes through datetime' {
            $dt = [datetime]'2025-06-15T12:30:00'
            Copy-Object $dt | Should -Be $dt
        }

        It 'passes through enum' {
            Copy-Object ([System.DayOfWeek]::Monday) | Should -Be ([System.DayOfWeek]::Monday)
        }

        It 'passes through guid' {
            $guid = [guid]::NewGuid()
            Copy-Object $guid | Should -Be $guid
        }
    }

    Context 'hashtable' {
        It 'clones a simple hashtable' {
            $original = @{ a = 1; b = 2 }
            $clone = Copy-Object $original
            $clone.a | Should -Be 1
            $clone.b | Should -Be 2
        }

        It 'returns a different reference' {
            $original = @{ a = 1 }
            $clone = Copy-Object $original
            [object]::ReferenceEquals($original, $clone) | Should -BeFalse
        }

        It 'mutating original does not affect clone' {
            $original = @{ key = 'before' }
            $clone = Copy-Object $original
            $original.key = 'after'
            $clone.key | Should -Be 'before'
        }

        It 'mutating clone does not affect original' {
            $original = @{ key = 'before' }
            $clone = Copy-Object $original
            $clone.key = 'after'
            $original.key | Should -Be 'before'
        }

        It 'clones empty hashtable' {
            $clone = Copy-Object @{}
            $clone | Should -BeOfType [hashtable]
            $clone.Count | Should -Be 0
        }

        It 'preserves hashtable type' {
            $clone = Copy-Object @{ a = 1 }
            $clone | Should -BeOfType [hashtable]
        }
    }

    Context 'ordered dictionary' {
        It 'preserves key order' {
            $original = [ordered]@{ z = 1; a = 2; m = 3 }
            $clone = Copy-Object $original
            @($clone.Keys) | Should -Be @('z', 'a', 'm')
        }

        It 'preserves ordered dictionary type' {
            $original = [ordered]@{ a = 1 }
            $clone = Copy-Object $original
            $clone | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }

        It 'returns a different reference' {
            $original = [ordered]@{ a = 1 }
            $clone = Copy-Object $original
            [object]::ReferenceEquals($original, $clone) | Should -BeFalse
        }

        It 'mutating original does not affect clone' {
            $original = [ordered]@{ key = 'before' }
            $clone = Copy-Object $original
            $original.key = 'after'
            $clone.key | Should -Be 'before'
        }

        It 'clones empty ordered dictionary' {
            $clone = Copy-Object ([ordered]@{})
            $clone | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            $clone.Count | Should -Be 0
        }
    }

    Context 'PSCustomObject' {
        It 'clones properties' {
            $original = [PSCustomObject]@{ Name = 'test'; Count = 42 }
            $clone = Copy-Object $original -AcceptWarnings
            $clone.Name | Should -Be 'test'
            $clone.Count | Should -Be 42
        }

        It 'returns a different reference' {
            $original = [PSCustomObject]@{ A = 1 }
            $clone = Copy-Object $original -AcceptWarnings
            [object]::ReferenceEquals($original, $clone) | Should -BeFalse
        }

        It 'mutating original does not affect clone' {
            $original = [PSCustomObject]@{ Value = 'before' }
            $clone = Copy-Object $original -AcceptWarnings
            $original.Value = 'after'
            $clone.Value | Should -Be 'before'
        }

        It 'clones PSCustomObject with nested hashtable' {
            $original = [PSCustomObject]@{ Config = @{ key = 'val' } }
            $clone = Copy-Object $original -AcceptWarnings
            $original.Config.key = 'changed'
            $clone.Config.key | Should -Be 'val'
        }

        It 'clones PSCustomObject with nested ordered dictionary' {
            $original = [PSCustomObject]@{ Config = [ordered]@{ a = 1; b = 2 } }
            $clone = Copy-Object $original -AcceptWarnings
            $clone.Config | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            $original.Config.a = 99
            $clone.Config.a | Should -Be 1
        }

        It 'clones PSCustomObject with nested PSCustomObject' {
            $inner = [PSCustomObject]@{ Deep = 'value' }
            $original = [PSCustomObject]@{ Child = $inner }
            $clone = Copy-Object $original -AcceptWarnings
            $original.Child.Deep = 'changed'
            $clone.Child.Deep | Should -Be 'value'
        }
    }

    Context 'PSCustomObject verbose' {
        It 'emits verbose when cloning PSCustomObject' {
            $output = Copy-Object ([PSCustomObject]@{ A = 1 }) -Verbose 4>&1 | Out-String
            $output | Should -Match 'Only copying note properties'
        }

        It 'no verbose for non-PSCustomObject types' {
            $verbose = Copy-Object @{ a = 1 } -Verbose 4>&1 | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }
            $verbose | Should -BeNullOrEmpty
        }
    }

    Context 'arrays' {
        It 'clones a simple array' {
            $clone = Copy-Object @(1, 2, 3)
            $clone | Should -Be @(1, 2, 3)
        }

        It 'returns array type' {
            $clone = Copy-Object @(1, 2)
            $clone.GetType().IsArray | Should -BeTrue
        }

        It 'returns a different reference' {
            $original = @(1, 2)
            $clone = Copy-Object $original
            [object]::ReferenceEquals($original, $clone) | Should -BeFalse
        }

        It 'clones empty array' {
            $clone = Copy-Object @()
            $clone | Should -HaveCount 0
        }

        It 'clones single-element array' {
            $clone = Copy-Object @(42)
            $clone | Should -HaveCount 1
            $clone[0] | Should -Be 42
        }

        It 'clones array of strings' {
            $clone = Copy-Object @('a', 'b', 'c')
            $clone | Should -Be @('a', 'b', 'c')
        }

        It 'deep clones array of hashtables' {
            $original = @(@{ a = 1 }, @{ b = 2 })
            $clone = Copy-Object $original
            $original[0].a = 99
            $clone[0].a | Should -Be 1
        }

        It 'deep clones array of PSCustomObjects' {
            $original = @(
                [PSCustomObject]@{ X = 'one' }
                [PSCustomObject]@{ X = 'two' }
            )
            $clone = Copy-Object $original -AcceptWarnings
            $original[0].X = 'changed'
            $clone[0].X | Should -Be 'one'
            $clone[1].X | Should -Be 'two'
        }

        It 'deep clones nested arrays' {
            $inner = @(@{ val = 'deep' })
            $original = @($inner, 'flat')
            $clone = Copy-Object $original
            $inner[0].val = 'changed'
            $clone[0][0].val | Should -Be 'deep'
        }
    }

    Context 'deeply nested structures' {
        It 'clones 5 levels deep — hashtable in ordered in PSCustomObject in array in hashtable' {
            $original = @{
                level1 = @(
                    [PSCustomObject]@{
                        level3 = [ordered]@{
                            level4 = @{
                                level5 = 'deep value'
                            }
                        }
                    }
                )
            }
            $clone = Copy-Object $original -AcceptWarnings
            $original.level1[0].level3.level4.level5 = 'changed'
            $clone.level1[0].level3.level4.level5 | Should -Be 'deep value'
        }

        It 'preserves types at every nesting level' {
            $original = [ordered]@{
                arr = @(
                    [PSCustomObject]@{
                        ht = @{ inner = [ordered]@{ leaf = 1 } }
                    }
                )
            }
            $clone = Copy-Object $original -AcceptWarnings
            $clone | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            $clone.arr.GetType().IsArray | Should -BeTrue
            $clone.arr[0].GetType().Name | Should -Be 'PSCustomObject'
            $clone.arr[0].ht | Should -BeOfType [hashtable]
            $clone.arr[0].ht.inner | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }
    }

    Context 'mixed value types in containers' {
        It 'clones hashtable with mixed value types' {
            $original = @{
                str  = 'text'
                num  = 42
                bool = $true
                date = [datetime]'2025-01-01'
                arr  = @(1, 2)
                ht   = @{ nested = 'yes' }
                nil  = $null
            }
            $clone = Copy-Object $original
            $clone.str | Should -Be 'text'
            $clone.num | Should -Be 42
            $clone.bool | Should -BeTrue
            $clone.date | Should -Be ([datetime]'2025-01-01')
            $clone.arr | Should -Be @(1, 2)
            $clone.ht.nested | Should -Be 'yes'
            $clone.nil | Should -BeNullOrEmpty
        }
    }

    Context 'isolation — no shared references at any level' {
        It 'adding key to original hashtable does not affect clone' {
            $original = @{ a = 1 }
            $clone = Copy-Object $original
            $original.b = 2
            $clone.Contains('b') | Should -BeFalse
        }

        It 'removing key from original hashtable does not affect clone' {
            $original = @{ a = 1; b = 2 }
            $clone = Copy-Object $original
            $original.Remove('b')
            $clone.b | Should -Be 2
        }

        It 'nested dictionary mutation in original does not affect clone' {
            $original = @{ outer = @{ inner = @{ deep = 'original' } } }
            $clone = Copy-Object $original
            $original.outer.inner.deep = 'mutated'
            $clone.outer.inner.deep | Should -Be 'original'
        }

        It 'nested dictionary mutation in clone does not affect original' {
            $original = @{ outer = @{ inner = @{ deep = 'original' } } }
            $clone = Copy-Object $original
            $clone.outer.inner.deep = 'mutated'
            $original.outer.inner.deep | Should -Be 'original'
        }

        It 'array element replacement in original does not affect clone' {
            $original = @(@{ x = 1 }, @{ x = 2 })
            $clone = Copy-Object $original
            $original[0] = @{ x = 99 }
            $clone[0].x | Should -Be 1
        }
    }

    Context 'real-world: meta configuration' {
        BeforeAll {
            $script:config = Get-MetaConfiguration
            $script:clone = Copy-Object $config
        }

        It 'clone has same top-level keys' {
            @($clone.Keys) | Should -Be @($config.Keys)
        }

        It 'clone has same customers' {
            @($clone.customers.Keys) | Should -Be @($config.customers.Keys)
        }

        It 'clone has same environments' {
            @($clone.environments.Keys) | Should -Be @($config.environments.Keys)
        }

        It 'customers are not the same reference' {
            [object]::ReferenceEquals($config.customers, $clone.customers) | Should -BeFalse
        }

        It 'individual customer is not the same reference' {
            [object]::ReferenceEquals($config.customers.blue, $clone.customers.blue) | Should -BeFalse
        }

        It 'mutating clone customer does not affect original' {
            $clone.customers.blue.details = 'MUTATED'
            $config.customers.blue.details | Should -Not -Be 'MUTATED'
        }
    }

    Context 'pipeline' {
        It 'accepts single object via pipeline' {
            $clone = @{ a = 1 } | Copy-Object
            $clone.a | Should -Be 1
        }

        It 'accepts positional parameter' {
            $clone = Copy-Object @{ a = 1 }
            $clone.a | Should -Be 1
        }
    }
}
