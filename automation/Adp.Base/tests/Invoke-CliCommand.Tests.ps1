Describe 'Invoke-CliCommand' {
    It 'runs a command successfully' {
        { Invoke-CliCommand 'echo hello' } | Should -Not -Throw
    }

    It 'captures output with -PassThru' {
        $script:result = Invoke-CliCommand 'echo hello' -PassThru
        $result | Should -Be 'hello'
    }

    It 'throws on non-zero exit code by default' {
        { Invoke-CliCommand 'cmd /c exit 1' } | Should -Throw
    }

    It 'does not throw with -NoAssert' {
        { Invoke-CliCommand 'cmd /c exit 1' -NoAssert } | Should -Not -Throw
    }
}
