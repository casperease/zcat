Describe 'Assert-PipelineCount' {
    Context 'Equals' {
        It 'passes when count matches' {
            { @(1, 2, 3) | Assert-PipelineCount 3 } | Should -Not -Throw
        }

        It 'throws when count does not match' {
            { @(1, 2) | Assert-PipelineCount 3 } | Should -Throw
        }

        It 'passes through pipeline objects' {
            $result = @(1, 2, 3) | Assert-PipelineCount 3
            $result | Should -HaveCount 3
        }
    }

    Context 'Minimum' {
        It 'passes when count meets minimum' {
            { @(1, 2, 3) | Assert-PipelineCount -Minimum 2 } | Should -Not -Throw
        }

        It 'throws when count is below minimum' {
            { @(1) | Assert-PipelineCount -Minimum 2 } | Should -Throw
        }
    }

    Context 'Maximum' {
        It 'passes when count is within maximum' {
            { @(1, 2) | Assert-PipelineCount -Maximum 3 } | Should -Not -Throw
        }

        It 'throws when count exceeds maximum' {
            { @(1, 2, 3, 4) | Assert-PipelineCount -Maximum 2 } | Should -Throw
        }
    }

    It 'throws when called with direct input' {
        { Assert-PipelineCount -InputObject 'x' -Equals 1 } | Should -Throw -ExpectedMessage '*pipeline*'
    }
}
