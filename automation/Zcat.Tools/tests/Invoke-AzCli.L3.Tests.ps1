Describe 'Invoke-AzCli' -Tag 'L3' {
    BeforeAll {
        $script:available = Test-Tool 'AzCli'
    }

    It 'returns version as JSON with accessible properties' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'AzCli not available'; return }
        $result = Invoke-AzCli 'version --output json' -PassThru -Silent
        $result.ExitCode | Should -Be 0
        $version = $result.Output | ConvertFrom-Json
        $version.'azure-cli' | Should -Not -BeNullOrEmpty
    }
}
