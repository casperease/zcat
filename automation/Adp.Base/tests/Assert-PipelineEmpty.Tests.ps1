Describe 'Assert-PipelineEmpty' {
    It 'passes when pipeline is empty' {
        { @() | Assert-PipelineEmpty } | Should -Not -Throw
    }

    It 'throws when pipeline has objects' {
        { @(1) | Assert-PipelineEmpty } | Should -Throw
    }

    It 'throws on first object without waiting' {
        { 1, 2, 3 | Assert-PipelineEmpty } | Should -Throw
    }

    It 'throws when called with direct input' {
        { Assert-PipelineEmpty -InputObject 'x' } | Should -Throw -ExpectedMessage '*pipeline*'
    }
}
