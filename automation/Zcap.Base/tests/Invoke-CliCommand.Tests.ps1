Describe 'Invoke-CliCommand' {
    It 'CliRunner.cs asset exists' {
        Join-Path $PSScriptRoot '../assets/CliRunner.cs' | Should -Exist
    }

    It 'runs a command successfully' {
        { Invoke-CliCommand 'echo hello' } | Should -Not -Throw
    }

    It 'returns $null without -PassThru' {
        $result = Invoke-CliCommand 'echo hello'
        $result | Should -BeNullOrEmpty
    }

    It '-Direct passes output through (like typing the command)' {
        $result = Invoke-CliCommand 'echo hello' -Direct
        $result | Should -Be 'hello'
    }

    It 'returns Zcap.CliResult with -PassThru' {
        $result = Invoke-CliCommand 'echo hello' -PassThru
        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.TypeNames | Should -Contain 'Zcap.CliResult'
    }

    It 'Output contains stdout' {
        $result = Invoke-CliCommand 'echo hello' -PassThru
        $result.Output | Should -Be 'hello'
    }

    It 'Output is a string, not an array' {
        $echoCmd = if ($IsWindows) { 'cmd /c "echo line1 & echo line2"' } else { 'bash -c "echo line1; echo line2"' }
        $result = Invoke-CliCommand $echoCmd -PassThru
        $result.Output | Should -BeOfType [string]
        $result.Output | Should -Match 'line1'
        $result.Output | Should -Match 'line2'
    }

    It 'Errors contains stderr' {
        $errCmd = if ($IsWindows) { 'cmd /c "echo errtext 1>&2"' } else { 'bash -c "echo errtext >&2"' }
        $result = Invoke-CliCommand $errCmd -PassThru -NoAssert
        $result.Errors | Should -Match 'errtext'
    }

    It 'Full contains both stdout and stderr' {
        $bothCmd = if ($IsWindows) { 'cmd /c "echo out & echo err 1>&2"' } else { 'bash -c "echo out; echo err >&2"' }
        $result = Invoke-CliCommand $bothCmd -PassThru -NoAssert
        $result.Full | Should -Match 'out'
        $result.Full | Should -Match 'err'
    }

    It 'ExitCode is 0 on success' {
        $result = Invoke-CliCommand 'echo hello' -PassThru
        $result.ExitCode | Should -Be 0
    }

    It 'ExitCode captures non-zero with -NoAssert' {
        $failCmd = if ($IsWindows) { 'cmd /c exit 42' } else { 'bash -c "exit 42"' }
        $result = Invoke-CliCommand $failCmd -PassThru -NoAssert
        $result.ExitCode | Should -Be 42
    }

    It 'throws on non-zero exit code by default' {
        $failCmd = if ($IsWindows) { 'cmd /c exit 1' } else { 'bash -c "exit 1"' }
        { Invoke-CliCommand $failCmd } | Should -Throw
    }

    It 'does not throw with -NoAssert' {
        $failCmd = if ($IsWindows) { 'cmd /c exit 1' } else { 'bash -c "exit 1"' }
        { Invoke-CliCommand $failCmd -NoAssert } | Should -Not -Throw
    }

    It 'Raw is an array of unprocessed output' {
        $echoCmd = if ($IsWindows) { 'cmd /c "echo line1 & echo line2"' } else { 'bash -c "echo line1; echo line2"' }
        $result = Invoke-CliCommand $echoCmd -PassThru
        $result.Raw | Should -BeOfType [object]
        $result.Raw.Count | Should -BeGreaterOrEqual 2
    }

    It 'throws when -PassThru used with -Direct' {
        { Invoke-CliCommand 'echo hello' -PassThru -Direct } | Should -Throw '*-PassThru*'
    }

    It 'returns command string with -DryRun' {
        $result = Invoke-CliCommand 'echo hello' -DryRun
        $result | Should -Be 'echo hello'
        $result | Should -BeOfType [string]
    }
}
