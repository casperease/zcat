Describe 'Invoke-CliCommand' {
    It 'runs a command successfully' {
        { Invoke-CliCommand 'echo hello' } | Should -Not -Throw
    }

    It 'captures output with -PassThru' {
        $script:result = Invoke-CliCommand 'echo hello' -PassThru
        $result | Should -Be 'hello'
    }

    It 'throws on non-zero exit code by default' {
        $failCmd = if ($IsWindows) { 'cmd /c exit 1' } else { 'bash -c "exit 1"' }
        { Invoke-CliCommand $failCmd } | Should -Throw
    }

    It 'does not throw with -NoAssert' {
        $failCmd = if ($IsWindows) { 'cmd /c exit 1' } else { 'bash -c "exit 1"' }
        { Invoke-CliCommand $failCmd -NoAssert } | Should -Not -Throw
    }
}
