BeforeAll {
    $script:obj = [pscustomobject]@{ Name = 'test'; Value = 42 }
}

Describe 'Test-HaveProperty' {
    It 'returns $true when property exists' {
        Test-HaveProperty $obj 'Name' | Should -BeTrue
    }

    It 'returns $false when property is missing' {
        Test-HaveProperty $obj 'Missing' | Should -BeFalse
    }
}
