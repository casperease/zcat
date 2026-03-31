Describe 'Get-ToolConfig' {
    # Discovery-time: populates -ForEach data before tests run
    $script:configPath = Join-Path $PSScriptRoot '../assets/config/tools.yml'
    $script:allTools = Get-Content $configPath -Raw | ConvertFrom-Yaml
    $script:toolEntries = foreach ($key in $script:allTools.Keys) {
        @{ Tool = $key; Config = $script:allTools[$key] }
    }
    $script:depEntries = foreach ($entry in $script:toolEntries) {
        if ($entry.Config.DependsOn) {
            @{ Tool = $entry.Tool; DependsOn = $entry.Config.DependsOn }
        }
    }

    # Run-time: makes data available inside It blocks
    BeforeAll {
        $script:configPath = Join-Path $PSScriptRoot '../assets/config/tools.yml'
        $script:allTools = Get-Content $configPath -Raw | ConvertFrom-Yaml
    }

    Context 'asset dependencies' {
        It 'tools.yml exists' {
            Join-Path $PSScriptRoot '../assets/config/tools.yml' | Should -Exist
        }

        It 'dotnet-install.ps1 exists' {
            Join-Path $PSScriptRoot '../assets/scripts/dotnet-install.ps1' | Should -Exist
        }

        It 'dotnet-install.sh exists' {
            Join-Path $PSScriptRoot '../assets/scripts/dotnet-install.sh' | Should -Exist
        }
    }

    Context 'structural validation' {
        It 'tools.yml has at least one tool defined' {
            $script:allTools.Keys.Count | Should -BeGreaterThan 0
        }

        It '<Tool> has required fields' -ForEach $script:toolEntries {
            $Config.Version | Should -Not -BeNullOrEmpty -Because "$Tool needs a locked version"
            $Config.Command | Should -Not -BeNullOrEmpty -Because "$Tool needs a command name"
            $Config.VersionCommand | Should -Not -BeNullOrEmpty -Because "$Tool needs a version probe command"
            $Config.VersionPattern | Should -Not -BeNullOrEmpty -Because "$Tool needs a version regex"
        }

        It '<Tool> VersionPattern has a named capture group "ver"' -ForEach $script:toolEntries {
            $Config.VersionPattern | Should -Match '\(\?<ver>' -Because "VersionPattern must capture as (?<ver>...)"
        }

        It '<Tool> has at least one install mechanism' -ForEach $script:toolEntries {
            $hasMechanism = $Config.WingetId -or $Config.BrewFormula -or $Config.AptPackage -or $Config.PipPackage -or $Config.ScriptInstall
            $hasMechanism | Should -BeTrue -Because "$Tool needs WingetId, BrewFormula, AptPackage, PipPackage, or ScriptInstall"
        }

        It '<Tool> DependsOn references an existing tool' -ForEach $script:depEntries {
            $script:allTools.Keys | Should -Contain $DependsOn -Because "$Tool depends on $DependsOn which must exist in tools.yml"
        }
    }

    Context 'Install/Uninstall function coverage' {
        It '<Tool> has an Install-<Tool> function' -ForEach $script:toolEntries {
            Get-Command "Install-$Tool" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "every tool needs an Install-$Tool function"
        }

        It '<Tool> has an Uninstall-<Tool> function' -ForEach $script:toolEntries {
            Get-Command "Uninstall-$Tool" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "every tool needs an Uninstall-$Tool function"
        }
    }

    Context 'Get-ToolConfig behavior' {
        It 'returns config for <Tool>' -ForEach $script:toolEntries {
            $script:result = & (Get-Module Zcap.Tools) { Get-ToolConfig -Tool $args[0] } $Tool
            $result | Should -Not -BeNullOrEmpty
            $result.Version | Should -Be $Config.Version
            $result.Command | Should -Be $Config.Command
        }

        It 'throws for unknown tool' {
            { & (Get-Module Zcap.Tools) { Get-ToolConfig -Tool 'FakeTool' } } | Should -Throw '*Unknown tool*'
        }

        It 'caches across calls' {
            $script:first = & (Get-Module Zcap.Tools) { Get-ToolConfig -Tool 'Python' }
            $script:second = & (Get-Module Zcap.Tools) { Get-ToolConfig -Tool 'Python' }
            [object]::ReferenceEquals($first, $second) | Should -BeTrue -Because 'repeated calls should return the same cached object'
        }
    }
}
