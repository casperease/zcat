Describe 'Invoke-CliCommand' {
    # Use where.exe/which as the test command — real executables on all platforms.
    # 'echo' is a shell builtin on Windows (no echo.exe) and breaks Stream mode.
    BeforeAll {
        $script:simpleCmd = if ($IsWindows) { 'where.exe where' } else { 'which which' }
        $script:failCmd = if ($IsWindows) { 'cmd /c exit 1' } else { 'bash -c "exit 1"' }
        $script:fail42Cmd = if ($IsWindows) { 'cmd /c exit 42' } else { 'bash -c "exit 42"' }
        $script:multiLineCmd = if ($IsWindows) { 'cmd /c "echo line1 & echo line2"' } else { 'bash -c "echo line1; echo line2"' }
        $script:stderrCmd = if ($IsWindows) { 'cmd /c "echo errtext 1>&2"' } else { 'bash -c "echo errtext >&2"' }
        $script:bothCmd = if ($IsWindows) { 'cmd /c "echo out & echo err 1>&2"' } else { 'bash -c "echo out; echo err >&2"' }
    }

    Context 'asset dependencies' {
        It 'CliRunner.cs exists' {
            Join-Path $PSScriptRoot '../assets/CliRunner.cs' | Should -Exist
        }
    }

    Context 'DryRun' {
        It 'returns command string in default (Stream) mode' {
            $result = Invoke-CliCommand 'anything here' -DryRun
            $result | Should -Be 'anything here'
            $result | Should -BeOfType [string]
        }

        It 'returns command string with -Direct' {
            $result = Invoke-CliCommand 'anything here' -Direct -DryRun
            $result | Should -Be 'anything here'
        }

        It 'does not execute the command' {
            { Invoke-CliCommand $failCmd -DryRun } | Should -Not -Throw
        }
    }

    Context 'Stream mode (default) — execution' {
        It 'runs a command successfully' {
            { Invoke-CliCommand $simpleCmd } | Should -Not -Throw
        }

        It 'returns $null without -PassThru' {
            $result = Invoke-CliCommand $simpleCmd
            $result | Should -BeNullOrEmpty
        }

        It 'throws on non-zero exit code' {
            { Invoke-CliCommand $failCmd } | Should -Throw
        }

        It 'does not throw with -NoAssert' {
            { Invoke-CliCommand $failCmd -NoAssert } | Should -Not -Throw
        }
    }

    Context 'Stream mode — PassThru result object' {
        It 'returns Zcap.CliResult type' {
            $result = Invoke-CliCommand $simpleCmd -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.TypeNames | Should -Contain 'Zcap.CliResult'
        }

        It '.Output contains stdout' {
            $result = Invoke-CliCommand $simpleCmd -PassThru
            $result.Output | Should -Not -BeNullOrEmpty
        }

        It '.Output is a string not an array for multi-line' {
            $result = Invoke-CliCommand $multiLineCmd -PassThru
            $result.Output | Should -BeOfType [string]
            $result.Output | Should -Match 'line1'
            $result.Output | Should -Match 'line2'
        }

        It '.Errors contains stderr' {
            $result = Invoke-CliCommand $stderrCmd -PassThru -NoAssert
            $result.Errors | Should -Match 'errtext'
        }

        It '.Full contains both stdout and stderr' {
            $result = Invoke-CliCommand $bothCmd -PassThru -NoAssert
            $result.Full | Should -Match 'out'
            $result.Full | Should -Match 'err'
        }

        It '.ExitCode is 0 on success' {
            $result = Invoke-CliCommand $simpleCmd -PassThru
            $result.ExitCode | Should -Be 0
        }

        It '.ExitCode captures non-zero with -NoAssert' {
            $result = Invoke-CliCommand $fail42Cmd -PassThru -NoAssert
            $result.ExitCode | Should -Be 42
        }

        It '.Raw is an array of output lines' {
            $result = Invoke-CliCommand $multiLineCmd -PassThru
            $result.Raw.Count | Should -BeGreaterOrEqual 2
        }
    }

    Context 'Stream mode — Silent' {
        It 'returns $null with -Silent and no -PassThru' {
            $result = Invoke-CliCommand $simpleCmd -Silent
            $result | Should -BeNullOrEmpty
        }

        It '-PassThru -Silent still captures output' {
            $result = Invoke-CliCommand $simpleCmd -PassThru -Silent
            $result.Output | Should -Not -BeNullOrEmpty
        }

        It '-Silent does not affect exit code assertion' {
            { Invoke-CliCommand $failCmd -Silent } | Should -Throw
        }
    }

    Context 'Stream mode — no pipeline leak' {
        It 'output does not leak into caller function return' {
            function Test-StreamLeak { Invoke-CliCommand $simpleCmd }
            $leaked = Test-StreamLeak
            $leaked | Should -BeNullOrEmpty
        }

        It 'multi-line output does not leak' {
            function Test-MultiLineLeak { Invoke-CliCommand $multiLineCmd }
            $leaked = Test-MultiLineLeak
            $leaked | Should -BeNullOrEmpty
        }
    }

    Context 'Direct mode' {
        It 'output leaks to pipeline' {
            $result = Invoke-CliCommand 'echo hello' -Direct
            $result | Should -Be 'hello'
        }

        It 'throws on non-zero exit code' {
            { Invoke-CliCommand $failCmd -Direct } | Should -Throw
        }

        It 'does not throw with -NoAssert' {
            { Invoke-CliCommand $failCmd -Direct -NoAssert } | Should -Not -Throw
        }
    }

    Context 'parameter sets' {
        It '-PassThru and -Direct are mutually exclusive' {
            { Invoke-CliCommand 'echo hello' -PassThru -Direct } | Should -Throw '*Parameter set cannot be resolved*'
        }

        It '-PassThru without -Direct works' {
            $result = Invoke-CliCommand $simpleCmd -PassThru
            $result | Should -Not -BeNullOrEmpty
        }

        It '-Direct without -PassThru works' {
            { Invoke-CliCommand 'echo hello' -Direct } | Should -Not -Throw
        }
    }

    Context 'CliRunner parser — direct exec' {
        It 'handles simple command with output' {
            $result = Invoke-CliCommand $simpleCmd -PassThru -Silent
            $result.Output | Should -Not -BeNullOrEmpty
        }

        It 'handles multiple arguments' {
            $result = Invoke-CliCommand $multiLineCmd -PassThru -Silent
            $result.Output | Should -Match 'line1'
            $result.Output | Should -Match 'line2'
        }
    }

    Context 'CliRunner parser — shell operators rejected' {
        It 'unquoted pipe throws' {
            { Invoke-CliCommand 'where.exe foo | where.exe bar' -Silent } | Should -Throw
        }

        It 'unquoted && throws' {
            { Invoke-CliCommand 'where.exe foo && where.exe bar' -Silent } | Should -Throw
        }

        It 'unquoted ; throws' {
            { Invoke-CliCommand 'where.exe foo ; where.exe bar' -Silent } | Should -Throw
        }

        It 'unquoted & throws' {
            { Invoke-CliCommand 'where.exe foo & where.exe bar' -Silent } | Should -Throw
        }

        It 'pipe inside quotes does NOT throw' {
            # The parser should not reject this — the | is inside quotes.
            $cmd = if ($IsWindows) { 'where.exe "foo|bar"' } else { 'which "foo|bar"' }
            { Invoke-CliCommand $cmd -Silent -NoAssert } | Should -Not -Throw
        }
    }
}
