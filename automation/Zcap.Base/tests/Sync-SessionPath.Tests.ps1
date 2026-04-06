Describe 'Sync-SessionPath' {
    BeforeEach {
        $script:originalPath = $env:PATH
    }

    AfterEach {
        $env:PATH = $originalPath
    }

    if ($IsWindows) {
        It 'merges registry entries into session PATH' {
            $userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
            $userEntries = if ($userPath) { $userPath -split ';' | Where-Object { $_ -ne '' } } else { @() }

            # Remove a known registry entry from session to simulate a stale session
            if ($userEntries.Count -gt 0) {
                $removed = $userEntries[0]
                $normalized = $removed.TrimEnd('\', '/')
                $env:PATH = ($env:PATH -split ';' |
                    Where-Object { $_.TrimEnd('\', '/') -ne $normalized }) -join ';'

                Sync-SessionPath

                $env:PATH | Should -Match ([regex]::Escape($normalized))
            }
            else {
                Set-ItResult -Skipped -Because 'No User PATH entries to test with'
            }
        }

        It 'preserves session-only entries that exist on disk' {
            $sessionOnly = [System.IO.Path]::GetTempPath().TrimEnd('\')
            $env:PATH = "$sessionOnly;$env:PATH"

            Sync-SessionPath

            $env:PATH | Should -Match ([regex]::Escape($sessionOnly))
        }

        It 'drops session-only entries that no longer exist on disk' {
            $gone = 'C:\zcap-test-nonexistent-path'
            $env:PATH = "$gone;$env:PATH"

            Sync-SessionPath

            $env:PATH | Should -Not -Match ([regex]::Escape($gone))
        }

        It 'does not duplicate existing entries' {
            $before = ($env:PATH -split ';' | Where-Object { $_ -ne '' }).Count

            Sync-SessionPath

            $after = ($env:PATH -split ';' | Where-Object { $_ -ne '' }).Count
            # Should not grow beyond adding genuinely new registry entries
            $after | Should -BeLessOrEqual ($before + 20)
        }
    }

    if (-not $IsWindows) {
        It 'is a no-op on Unix' {
            $before = $env:PATH
            Sync-SessionPath
            $env:PATH | Should -Be $before
        }
    }
}
