Describe 'Assert-Command' {
    It 'passes for an installed command' {
        { Assert-Command 'pwsh' } | Should -Not -Throw
    }

    It 'throws for a missing command' {
        { Assert-Command 'not-a-real-command-xyz' } | Should -Throw
    }
}
