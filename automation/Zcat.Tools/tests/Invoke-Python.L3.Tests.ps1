Describe 'Invoke-Python' -Tag 'L3' {
    BeforeAll {
        $script:available = Test-Tool 'Python'
    }

    It 'executes inline Python and captures output' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'Python not available'; return }
        $result = Invoke-Python '-c "import sys; print(sys.executable)"' -PassThru -Silent
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Not -BeNullOrEmpty
    }

    It 'captures stdout and stderr separately' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'Python not available'; return }
        $result = Invoke-Python '-c "import sys; sys.stdout.write(''out\n''); sys.stderr.write(''err\n'')"' -PassThru -Silent -NoAssert
        $result.Output | Should -Be 'out'
        $result.Errors | Should -Be 'err'
        $result.Full | Should -Match 'out'
        $result.Full | Should -Match 'err'
    }

    It 'propagates non-zero exit code' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'Python not available'; return }
        $result = Invoke-Python '-c "import sys; sys.exit(42)"' -PassThru -Silent -NoAssert
        $result.ExitCode | Should -Be 42
    }

    It 'passes arguments with spaces correctly' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'Python not available'; return }
        $result = Invoke-Python '-c "print(''hello world'')"' -PassThru -Silent
        $result.Output | Should -Be 'hello world'
    }

    It 'passes arguments with equals sign' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'Python not available'; return }
        $result = Invoke-Python '-c "print(''key=value'')"' -PassThru -Silent
        $result.Output | Should -Be 'key=value'
    }

    It 'runs in repository root by default' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'Python not available'; return }
        $result = Invoke-Python '-c "import os; print(os.getcwd())"' -PassThru -Silent
        $result.Output | Should -Be $env:RepositoryRoot
    }

    It 'runs in explicit WorkingDirectory' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'Python not available'; return }
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        try {
            $result = Invoke-Executable "python -c ""import os; print(os.getcwd())""" -PassThru -Silent -WorkingDirectory $tempDir
            $result.Output | Should -Be $tempDir
        }
        finally {
            Remove-Item $tempDir -Force
        }
    }

    It 'captures multi-line output as array in .Raw' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'Python not available'; return }
        $result = Invoke-Python '-c "print(''line1\nline2\nline3'')"' -PassThru -Silent
        $result.Raw.Count | Should -Be 3
        $result.Raw[0] | Should -Be 'line1'
        $result.Raw[2] | Should -Be 'line3'
    }
}
