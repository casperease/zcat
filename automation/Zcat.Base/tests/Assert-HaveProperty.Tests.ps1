BeforeAll {
    $script:obj = [pscustomobject]@{ Name = 'test'; Value = 42 }
}

Describe 'Assert-HaveProperty' {
    It 'passes when property exists' {
        { Assert-HaveProperty $obj 'Name' } | Should -Not -Throw
    }

    It 'throws when property is missing' {
        { Assert-HaveProperty $obj 'Missing' } | Should -Throw
    }
}
