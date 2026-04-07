Describe 'Remove-PermanentPath' {
    BeforeAll {
        $script:tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "zcat-test-path-$([guid]::NewGuid().ToString('N').Substring(0,8))"
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        if ($IsWindows) {
            $script:savedUserPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
        }
    }

    AfterAll {
        if ($IsWindows) {
            [System.Environment]::SetEnvironmentVariable('PATH', $savedUserPath, 'User')
        }
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    BeforeEach {
        $script:originalPath = $env:PATH
    }

    AfterEach {
        $env:PATH = $originalPath
    }

    It 'removes path from session PATH' {
        $separator = [System.IO.Path]::PathSeparator
        $env:PATH = "$tempDir$separator$env:PATH"

        Remove-PermanentPath $tempDir

        $env:PATH | Should -Not -Match ([regex]::Escape($tempDir))
    }

    It 'is idempotent — no error when path is absent' {
        $before = $env:PATH
        Remove-PermanentPath (Join-Path $tempDir 'not-there')
        $env:PATH | Should -Not -BeNullOrEmpty
    }

    It 'preserves other entries' {
        $separator = [System.IO.Path]::PathSeparator
        $env:PATH = "$tempDir${separator}/keep/this${separator}/also/keep"

        Remove-PermanentPath $tempDir

        $env:PATH | Should -Match ([regex]::Escape('/keep/this'))
        $env:PATH | Should -Match ([regex]::Escape('/also/keep'))
    }

    if ($IsWindows) {
        Context 'Windows persistence' {
            BeforeEach {
                $script:originalUserPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
                # Inject our temp dir into the User registry PATH
                $injected = if ($originalUserPath) { "$tempDir;$originalUserPath" } else { $tempDir }
                [System.Environment]::SetEnvironmentVariable('PATH', $injected, 'User')
            }

            AfterEach {
                [System.Environment]::SetEnvironmentVariable('PATH', $originalUserPath, 'User')
            }

            It 'removes from User registry PATH' {
                Remove-PermanentPath $tempDir

                $userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
                $userPath | Should -Not -Match ([regex]::Escape($tempDir))
            }
        }
    }

    if (-not $IsWindows) {
        Context 'Unix persistence' {
            BeforeAll {
                $script:testProfile = Join-Path ([System.IO.Path]::GetTempPath()) "zcat-test-profile-$([guid]::NewGuid().ToString('N').Substring(0,8)).ps1"
            }

            AfterAll {
                Remove-Item $testProfile -Force -ErrorAction SilentlyContinue
            }

            It 'removes marker block from profile' {
                $originalProfile = $PROFILE.CurrentUserCurrentHost
                try {
                    $PROFILE | Add-Member -NotePropertyName CurrentUserCurrentHost -NotePropertyValue $testProfile -Force

                    # Set up: add a block first
                    Add-PermanentPath $tempDir -Label 'TestTool'
                    $content = Get-Content $testProfile -Raw
                    $content | Should -Match '>>> zcat PATH TestTool >>>'

                    # Act: remove it
                    Remove-PermanentPath $tempDir -Label 'TestTool'
                    $content = Get-Content $testProfile -Raw
                    $content | Should -Not -Match '>>> zcat PATH TestTool >>>'
                }
                finally {
                    $PROFILE | Add-Member -NotePropertyName CurrentUserCurrentHost -NotePropertyValue $originalProfile -Force
                }
            }
        }
    }
}
