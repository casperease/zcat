Describe 'ConvertFrom-PipelineCommand' {
    Context 'line ending normalization' {
        It 'converts \r\n to \n' {
            $result = ConvertFrom-PipelineCommand "line1`r`nline2"
            $result | Should -Be "line1`nline2"
        }

        It 'converts stray \r to \n' {
            $result = ConvertFrom-PipelineCommand "line1`rline2"
            $result | Should -Be "line1`nline2"
        }

        It 'preserves intentional newlines' {
            $input = "Get-Process`nGet-Service`nGet-ChildItem"
            $result = ConvertFrom-PipelineCommand $input
            $result | Should -Be "Get-Process`nGet-Service`nGet-ChildItem"
        }
    }

    Context 'whitespace cleanup' {
        It 'trims leading and trailing whitespace' {
            $result = ConvertFrom-PipelineCommand '   Test-Automation   '
            $result | Should -Be 'Test-Automation'
        }

        It 'trims leading and trailing blank lines' {
            $result = ConvertFrom-PipelineCommand "`n`nTest-Automation`n`n"
            $result | Should -Be 'Test-Automation'
        }

        It 'removes trailing whitespace per line' {
            $result = ConvertFrom-PipelineCommand "line1   `nline2   "
            $result | Should -Be "line1`nline2"
        }

        It 'preserves leading whitespace per line (indentation)' {
            $result = ConvertFrom-PipelineCommand "if (`$true) {`n    Get-Process`n}"
            $result | Should -Be "if (`$true) {`n    Get-Process`n}"
        }
    }

    Context 'single-line commands' {
        It 'returns a simple command unchanged' {
            $result = ConvertFrom-PipelineCommand 'Test-Automation'
            $result | Should -Be 'Test-Automation'
        }

        It 'handles commands with arguments' {
            $result = ConvertFrom-PipelineCommand 'Invoke-AzCli "account show" -PassThru'
            $result | Should -Be 'Invoke-AzCli "account show" -PassThru'
        }
    }

    Context 'multiline commands' {
        It 'preserves multiline pipeline commands' {
            $cmd = "`$config = Get-MetaConfiguration`n`$envs = Get-MetaEnvironments`nDeploy-Infrastructure -Config `$config"
            $result = ConvertFrom-PipelineCommand $cmd
            ($result -split "`n").Count | Should -Be 3
        }
    }
}
