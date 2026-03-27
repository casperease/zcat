Describe 'Assert-TypeIs' {
    It 'passes when type matches' {
        { Assert-TypeIs 'hello' 'System.String' } | Should -Not -Throw
    }

    It 'passes for int type' {
        { Assert-TypeIs 42 'System.Int32' } | Should -Not -Throw
    }

    It 'throws when type does not match' {
        { Assert-TypeIs 'hello' 'System.Int32' } | Should -Throw
    }

    It 'includes actual type in error message' {
        { Assert-TypeIs 'hello' 'System.Int32' } | Should -Throw -ExpectedMessage '*System.String*'
    }
}
