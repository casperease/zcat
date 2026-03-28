Describe 'Assert-LastExitCodeWasZero' {
    It 'passes when LASTEXITCODE is 0' {
        $global:LASTEXITCODE = 0
        { Assert-LastExitCodeWasZero } | Should -Not -Throw
    }

    It 'throws when LASTEXITCODE is non-zero' {
        $global:LASTEXITCODE = 1
        { Assert-LastExitCodeWasZero } | Should -Throw
    }

    It 'resets LASTEXITCODE by default' {
        $global:LASTEXITCODE = 0
        Assert-LastExitCodeWasZero
        Get-Variable LASTEXITCODE -Scope Global -ErrorAction Ignore | Should -BeNullOrEmpty
    }

    It 'preserves LASTEXITCODE with -DoNotReset' {
        $global:LASTEXITCODE = 0
        Assert-LastExitCodeWasZero -DoNotReset
        $global:LASTEXITCODE | Should -Be 0
    }
}
