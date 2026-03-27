Describe 'Get-LastExitCode' {
    It 'returns the exit code value' {
        $global:LASTEXITCODE = 42
        Get-LastExitCode | Should -Be 42
    }

    It 'returns nothing and warns when no exit code exists' {
        Remove-Variable LASTEXITCODE -Scope Global -ErrorAction Ignore
        Get-LastExitCode -WarningVariable w -WarningAction SilentlyContinue | Should -BeNullOrEmpty
        $w | Should -Not -BeNullOrEmpty
    }
}
