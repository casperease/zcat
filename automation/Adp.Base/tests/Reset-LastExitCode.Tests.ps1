Describe 'Reset-LastExitCode' {
    It 'removes LASTEXITCODE when it exists' {
        $global:LASTEXITCODE = 42
        Reset-LastExitCode
        Get-Variable LASTEXITCODE -Scope Global -ErrorAction Ignore | Should -BeNullOrEmpty
    }

    It 'does not throw when LASTEXITCODE does not exist' {
        Remove-Variable LASTEXITCODE -Scope Global -ErrorAction Ignore
        { Reset-LastExitCode } | Should -Not -Throw
    }
}
