Describe 'Invoke-Executable' {
    # Use where.exe/which as the test command — real executables on all platforms.
    # 'echo' is a shell builtin on Windows (no echo.exe) and breaks Stream mode.
    BeforeAll {
        $script:simpleCmd = if ($IsWindows) { 'where.exe where' } else { 'which which' }
        $script:failCmd = if ($IsWindows) { 'cmd /c exit 1' } else { 'bash -c "exit 1"' }
        $script:fail42Cmd = if ($IsWindows) { 'cmd /c exit 42' } else { 'bash -c "exit 42"' }
        $script:multiLineCmd = if ($IsWindows) { 'cmd /c "echo line1 & echo line2"' } else { 'bash -c "echo line1; echo line2"' }
        $script:stderrCmd = if ($IsWindows) { 'cmd /c "echo errtext 1>&2"' } else { 'bash -c "echo errtext >&2"' }
        $script:bothCmd = if ($IsWindows) { 'cmd /c "echo out & echo err 1>&2"' } else { 'bash -c "echo out; echo err >&2"' }
        $script:cwdCmd = if ($IsWindows) { 'cmd /c cd' } else { 'bash -c pwd' }
        $script:silentSuccessCmd = if ($IsWindows) { 'cmd /c exit 0' } else { 'bash -c "exit 0"' }
    }

    Context 'asset dependencies' {
        It 'CliRunner.cs exists' {
            Join-Path $PSScriptRoot '../assets/CliRunner.cs' | Should -Exist
        }
    }

    Context 'DryRun' {
        It 'returns command string in default (Stream) mode' {
            $result = Invoke-Executable 'anything here' -DryRun
            $result | Should -Be 'anything here'
            $result | Should -BeOfType [string]
        }

        It 'returns command string with -Direct' {
            $result = Invoke-Executable 'anything here' -Direct -DryRun
            $result | Should -Be 'anything here'
        }

        It 'does not execute the command' {
            { Invoke-Executable $failCmd -DryRun } | Should -Not -Throw
        }
    }

    Context 'Stream mode (default) — execution' {
        It 'runs a command successfully' {
            { Invoke-Executable $simpleCmd -Silent } | Should -Not -Throw
        }

        It 'returns $null without -PassThru' {
            $result = Invoke-Executable $simpleCmd -Silent
            $result | Should -BeNullOrEmpty
        }

        It 'throws on non-zero exit code' {
            { Invoke-Executable $failCmd -Silent } | Should -Throw
        }

        It 'does not throw with -NoAssert' {
            { Invoke-Executable $failCmd -NoAssert -Silent } | Should -Not -Throw
        }
    }

    Context 'Stream mode — PassThru result object' {
        It 'returns Zcat.CliResult type' {
            $result = Invoke-Executable $simpleCmd -PassThru -Silent
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.TypeNames | Should -Contain 'Zcat.CliResult'
        }

        It '.Output contains stdout' {
            $result = Invoke-Executable $simpleCmd -PassThru -Silent
            $result.Output | Should -Not -BeNullOrEmpty
        }

        It '.Output is a string not an array for multi-line' {
            $result = Invoke-Executable $multiLineCmd -PassThru -Silent
            $result.Output | Should -BeOfType [string]
            $result.Output | Should -Match 'line1'
            $result.Output | Should -Match 'line2'
        }

        It '.Errors contains stderr' {
            $result = Invoke-Executable $stderrCmd -PassThru -NoAssert -Silent
            $result.Errors | Should -Match 'errtext'
        }

        It '.Full contains both stdout and stderr' {
            $result = Invoke-Executable $bothCmd -PassThru -NoAssert -Silent
            $result.Full | Should -Match 'out'
            $result.Full | Should -Match 'err'
        }

        It '.ExitCode is 0 on success' {
            $result = Invoke-Executable $simpleCmd -PassThru -Silent
            $result.ExitCode | Should -Be 0
        }

        It '.ExitCode captures non-zero with -NoAssert' {
            $result = Invoke-Executable $fail42Cmd -PassThru -NoAssert -Silent
            $result.ExitCode | Should -Be 42
        }

        It '.Raw is an array of output lines' {
            $result = Invoke-Executable $multiLineCmd -PassThru -Silent
            $result.Raw.Count | Should -BeGreaterOrEqual 2
        }
    }

    Context 'Stream mode — Silent' {
        It 'returns $null with -Silent and no -PassThru' {
            $result = Invoke-Executable $simpleCmd -Silent
            $result | Should -BeNullOrEmpty
        }

        It '-PassThru -Silent still captures output' {
            $result = Invoke-Executable $simpleCmd -PassThru -Silent
            $result.Output | Should -Not -BeNullOrEmpty
        }

        It '-Silent does not affect exit code assertion' {
            { Invoke-Executable $failCmd -Silent } | Should -Throw
        }
    }

    Context 'Stream mode — no pipeline leak' {
        It 'output does not leak into caller function return' {
            function Test-StreamLeak { Invoke-Executable $simpleCmd -Silent }
            $leaked = Test-StreamLeak
            $leaked | Should -BeNullOrEmpty
        }

        It 'multi-line output does not leak' {
            function Test-MultiLineLeak { Invoke-Executable $multiLineCmd -Silent }
            $leaked = Test-MultiLineLeak
            $leaked | Should -BeNullOrEmpty
        }
    }

    Context 'Direct mode' {
        It 'output leaks to pipeline' {
            $result = Invoke-Executable 'echo hello' -Direct -Silent
            $result | Should -Be 'hello'
        }

        It 'throws on non-zero exit code' {
            { Invoke-Executable $failCmd -Direct -Silent } | Should -Throw
        }

        It 'does not throw with -NoAssert' {
            { Invoke-Executable $failCmd -Direct -NoAssert -Silent } | Should -Not -Throw
        }
    }

    Context 'parameter sets' {
        It '-PassThru and -Direct are mutually exclusive' {
            { Invoke-Executable 'echo hello' -PassThru -Direct } | Should -Throw '*Parameter set cannot be resolved*'
        }

        It '-PassThru without -Direct works' {
            $result = Invoke-Executable $simpleCmd -PassThru -Silent
            $result | Should -Not -BeNullOrEmpty
        }

        It '-Direct without -PassThru works' {
            { Invoke-Executable 'echo hello' -Direct -Silent } | Should -Not -Throw
        }
    }

    Context 'CliRunner parser — direct exec' {
        It 'handles simple command with output' {
            $result = Invoke-Executable $simpleCmd -PassThru -Silent
            $result.Output | Should -Not -BeNullOrEmpty
        }

        It 'handles multiple arguments' {
            $result = Invoke-Executable $multiLineCmd -PassThru -Silent
            $result.Output | Should -Match 'line1'
            $result.Output | Should -Match 'line2'
        }
    }

    Context 'WorkingDirectory' {
        It 'defaults to repository root in Stream mode' {
            Push-Location $env:TEMP
            try {
                $result = Invoke-Executable $cwdCmd -PassThru -Silent
                $result.Output.Trim() | Should -Be $env:RepositoryRoot
            }
            finally {
                Pop-Location
            }
        }

        It 'defaults to repository root in Direct mode' {
            Push-Location $env:TEMP
            try {
                $result = Invoke-Executable $cwdCmd -Direct -Silent
                ($result | Out-String).Trim() | Should -Be $env:RepositoryRoot
            }
            finally {
                Pop-Location
            }
        }

        It 'explicit -WorkingDirectory overrides default in Stream mode' {
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $tempDir | Out-Null
            try {
                $result = Invoke-Executable $cwdCmd -WorkingDirectory $tempDir -PassThru -Silent
                $result.Output.Trim() | Should -Be $tempDir
            }
            finally {
                Remove-Item $tempDir -Force
            }
        }

        It 'explicit -WorkingDirectory overrides default in Direct mode' {
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $tempDir | Out-Null
            try {
                $result = Invoke-Executable $cwdCmd -WorkingDirectory $tempDir -Direct -Silent
                ($result | Out-String).Trim() | Should -Be $tempDir
            }
            finally {
                Remove-Item $tempDir -Force
            }
        }

        It 'throws on non-existent path' {
            { Invoke-Executable $simpleCmd -WorkingDirectory 'C:\nonexistent\path\that\does\not\exist' -Silent } | Should -Throw
        }
    }

    Context 'Stream mode — empty output' {
        It '.Output is empty string when command produces no stdout' {
            $result = Invoke-Executable $silentSuccessCmd -PassThru -Silent
            $result.Output | Should -BeNullOrEmpty
            $result.ExitCode | Should -Be 0
        }

        It '.Errors is empty string on successful command' {
            $result = Invoke-Executable $simpleCmd -PassThru -Silent
            $result.Errors | Should -BeNullOrEmpty
        }
    }

    Context 'CliRunner parser — quoted arguments' {
        It 'quoted argument with spaces is passed as single argument' {
            # where.exe /? outputs help — proves the argument arrived intact.
            # More importantly: a space-containing quoted arg must not be split.
            $cmd = if ($IsWindows) { 'cmd /c echo "hello world"' } else { 'bash -c "echo hello world"' }
            $result = Invoke-Executable $cmd -PassThru -Silent
            $result.Output | Should -Match 'hello world'
        }
    }

    Context 'CliRunner parser — shell operators rejected' {
        It 'unquoted pipe throws' {
            { Invoke-Executable 'where.exe foo | where.exe bar' -Silent } | Should -Throw
        }

        It 'unquoted && throws' {
            { Invoke-Executable 'where.exe foo && where.exe bar' -Silent } | Should -Throw
        }

        It 'unquoted ; throws' {
            { Invoke-Executable 'where.exe foo ; where.exe bar' -Silent } | Should -Throw
        }

        It 'unquoted & throws' {
            { Invoke-Executable 'where.exe foo & where.exe bar' -Silent } | Should -Throw
        }

        It 'pipe inside quotes does NOT throw' {
            # The parser should not reject this — the | is inside quotes.
            $cmd = if ($IsWindows) { 'where.exe "foo|bar"' } else { 'which "foo|bar"' }
            { Invoke-Executable $cmd -Silent -NoAssert } | Should -Not -Throw
        }
    }
}
