Describe 'Get-ToolConfig' {
    It 'returns config for Python' {
        $script:config = & (Get-Module Zcap.Tools) { Get-ToolConfig -Tool 'Python' }
        $config | Should -Not -BeNullOrEmpty
        $config.Version | Should -Not -BeNullOrEmpty
        $config.Command | Should -Be 'python'
        $config.WingetId | Should -Not -BeNullOrEmpty
        $config.WingetScope | Should -Be 'user'
        $config.BrewFormula | Should -Not -BeNullOrEmpty
        $config.VersionCommand | Should -Not -BeNullOrEmpty
        $config.VersionPattern | Should -Not -BeNullOrEmpty
    }

    It 'returns config for Dotnet' {
        $script:config = & (Get-Module Zcap.Tools) { Get-ToolConfig -Tool 'Dotnet' }
        $config | Should -Not -BeNullOrEmpty
        $config.Version | Should -Not -BeNullOrEmpty
        $config.Command | Should -Be 'dotnet'
        $config.UserInstallDir | Should -Be '.dotnet'
        $config.VersionCommand | Should -Not -BeNullOrEmpty
        $config.VersionPattern | Should -Not -BeNullOrEmpty
    }

    It 'returns config for AzCli' {
        $script:config = & (Get-Module Zcap.Tools) { Get-ToolConfig -Tool 'AzCli' }
        $config | Should -Not -BeNullOrEmpty
        $config.Version | Should -Not -BeNullOrEmpty
        $config.Command | Should -Be 'az'
        $config.BrewFormula | Should -Not -BeNullOrEmpty
        $config.PipPackage | Should -Not -BeNullOrEmpty
        $config.VersionCommand | Should -Not -BeNullOrEmpty
        $config.VersionPattern | Should -Not -BeNullOrEmpty
    }

    It 'returns config for Poetry' {
        $script:config = & (Get-Module Zcap.Tools) { Get-ToolConfig -Tool 'Poetry' }
        $config | Should -Not -BeNullOrEmpty
        $config.Version | Should -Not -BeNullOrEmpty
        $config.Command | Should -Be 'poetry'
        $config.PipPackage | Should -Be 'poetry'
    }

    It 'throws for unknown tool' {
        { & (Get-Module Zcap.Tools) { Get-ToolConfig -Tool 'FakeTool' } } | Should -Throw '*Unknown tool*'
    }
}
