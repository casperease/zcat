Describe 'Assert-YmlNaming' {
    It 'passes for valid snake_case keys' {
        $yaml = [ordered]@{ foo_bar = 'value'; baz = [ordered]@{ nested_key = 1 } }
        { Assert-YmlNaming $yaml } | Should -Not -Throw
    }

    It 'throws for camelCase key' {
        $yaml = [ordered]@{ camelCase = 'value' }
        { Assert-YmlNaming $yaml } | Should -Throw '*not snake_case*'
    }

    It 'throws for kebab-case key' {
        $yaml = [ordered]@{ 'kebab-case' = 'value' }
        { Assert-YmlNaming $yaml } | Should -Throw '*not snake_case*'
    }

    It 'passes for nested structures with valid keys' {
        $yaml = [ordered]@{
            level_one = [ordered]@{
                level_two = [ordered]@{
                    level_three = 'deep'
                }
            }
        }
        { Assert-YmlNaming $yaml } | Should -Not -Throw
    }

    It 'ignores values — only checks keys' {
        $yaml = [ordered]@{ valid_key = 'camelCaseValue'; another_key = 'kebab-value' }
        { Assert-YmlNaming $yaml } | Should -Not -Throw
    }

    It 'PropertyPath prefixes error messages' {
        $yaml = [ordered]@{ 'Bad-Key' = 'value' }
        try {
            Assert-YmlNaming $yaml -PropertyPath 'root.section'
            throw 'Should not reach here'
        }
        catch {
            $_.Exception.Message | Should -Match 'root\.section\.Bad-Key'
        }
    }
}
