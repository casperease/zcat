Describe 'Add-PermanentPath' {
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

    It 'adds path to session PATH' {
        Add-PermanentPath $tempDir

        $env:PATH | Should -Match ([regex]::Escape($tempDir))
    }

    It 'appends by default' {
        Add-PermanentPath $tempDir

        $env:PATH | Should -Match "$([regex]::Escape($tempDir))$"
    }

    It 'prepends when -Prepend is set' {
        Add-PermanentPath $tempDir -Prepend

        $env:PATH | Should -Match "^$([regex]::Escape($tempDir))"
    }

    It 'is idempotent — does not duplicate' {
        Add-PermanentPath $tempDir
        $pathAfterFirst = $env:PATH

        Add-PermanentPath $tempDir
        $env:PATH | Should -Be $pathAfterFirst
    }

    It 'throws when path does not exist' {
        { Add-PermanentPath (Join-Path $tempDir 'nonexistent') } | Should -Throw
    }

    if ($IsWindows) {
        Context 'Windows persistence' {
            BeforeEach {
                $script:originalUserPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
            }

            AfterEach {
                [System.Environment]::SetEnvironmentVariable('PATH', $originalUserPath, 'User')
            }

            It 'writes to User registry PATH' {
                Add-PermanentPath $tempDir

                $userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
                $userPath | Should -Match ([regex]::Escape($tempDir))
            }

            It 'does not duplicate in registry on repeat call' {
                Add-PermanentPath $tempDir
                $first = [System.Environment]::GetEnvironmentVariable('PATH', 'User')

                Add-PermanentPath $tempDir
                $second = [System.Environment]::GetEnvironmentVariable('PATH', 'User')

                $second | Should -Be $first
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

            It 'writes marker block to profile' {
                # Temporarily override $PROFILE to point at our test file
                $originalProfile = $PROFILE.CurrentUserCurrentHost
                try {
                    $PROFILE | Add-Member -NotePropertyName CurrentUserCurrentHost -NotePropertyValue $testProfile -Force
                    Add-PermanentPath $tempDir -Label 'TestTool'
                    $content = Get-Content $testProfile -Raw
                    $content | Should -Match '>>> zcat PATH TestTool >>>'
                    $content | Should -Match ([regex]::Escape($tempDir))
                    $content | Should -Match '<<< zcat PATH TestTool <<<'
                }
                finally {
                    $PROFILE | Add-Member -NotePropertyName CurrentUserCurrentHost -NotePropertyValue $originalProfile -Force
                }
            }
        }
    }
}
