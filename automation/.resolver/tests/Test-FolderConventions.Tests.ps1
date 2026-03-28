BeforeDiscovery {
    $automationRoot = Join-Path $env:RepositoryRoot 'automation'

    $allowedModuleSubdirs = @('private', 'tests', 'config', 'scripts', 'assets')

    $modules = Get-ChildItem -Path $automationRoot -Directory |
        Where-Object { $_.Name -notmatch '^\.' }

    # Collect subdirectories for each module
    $moduleSubdirs = @()
    foreach ($moduleDir in $modules) {
        $subdirs = Get-ChildItem -Path $moduleDir.FullName -Directory -ErrorAction SilentlyContinue
        foreach ($subdir in $subdirs) {
            $moduleSubdirs += @{
                Module    = $moduleDir.Name
                Directory = $subdir.Name
                Allowed   = $allowedModuleSubdirs
            }
        }
    }

    # Find test files outside of tests/
    $misplacedTests = @()
    foreach ($moduleDir in $modules) {
        $rootTests = Get-ChildItem -Path $moduleDir.FullName -Filter '*.Tests.ps1' -File -ErrorAction SilentlyContinue
        foreach ($f in $rootTests) {
            $misplacedTests += @{
                Module   = $moduleDir.Name
                File     = $f.Name
                Location = 'module root'
            }
        }

        $privatePath = Join-Path $moduleDir.FullName 'private'
        if (Test-Path $privatePath) {
            $privateTests = Get-ChildItem -Path $privatePath -Filter '*.Tests.ps1' -File -ErrorAction SilentlyContinue
            foreach ($f in $privateTests) {
                $misplacedTests += @{
                    Module   = $moduleDir.Name
                    File     = $f.Name
                    Location = 'private/'
                }
            }
        }
    }
}

Describe 'Folder convention: <Module>/<Directory>' -ForEach $moduleSubdirs {
    It 'is a conventional folder name' {
        $Directory | Should -BeIn $Allowed -Because "module subdirectories must be one of: $($Allowed -join ', '). See ADR: conventional-folder-structure"
    }
}

Describe 'Misplaced test: <Module>/<File>' -ForEach $misplacedTests {
    It 'should be in tests/ not <Location>' {
        $Location | Should -Be 'tests/' -Because "test files belong in tests/, not $Location. See ADR: conventional-folder-structure"
    }
}
