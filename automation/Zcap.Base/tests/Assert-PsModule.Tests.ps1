Describe 'Assert-PsModule' {
    It 'passes for an available module' {
        { Assert-PsModule 'Pester' } | Should -Not -Throw
    }

    It 'throws for a missing module' {
        { Assert-PsModule 'Not.A.Real.Module.XYZ' } | Should -Throw
    }
}
