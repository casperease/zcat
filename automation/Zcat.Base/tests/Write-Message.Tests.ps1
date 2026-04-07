Describe 'Write-Message' {
    # Write-Message suppresses Host output when $global:__PesterRunning is $true
    # (set by Test-Automation). Lift the flag so these tests can verify Host output.
    BeforeAll { $global:__PesterRunning = $false }
    AfterAll { $global:__PesterRunning = $true }

    It 'writes with caller header by default' {
        Write-Message 'hello' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { if ($_.MessageData -is [string]) { $_.MessageData } else { $_.MessageData.Message } }) -join ''
        $text | Should -Match '\['
        $text | Should -Match 'hello'
    }

    It 'includes timestamp when ZCAT_MESSAGE_TIMESTAMPS is set' {
        $env:ZCAT_MESSAGE_TIMESTAMPS = '1'
        try {
            Write-Message 'hello' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
            $text = ($iv | ForEach-Object { if ($_.MessageData -is [string]) { $_.MessageData } else { $_.MessageData.Message } }) -join ''
            $text | Should -Match '\[\d{2}[.:]\d{2}[.:]\d{2}[.:]\d{3}'
        }
        finally {
            Remove-Item env:ZCAT_MESSAGE_TIMESTAMPS
        }
    }

    It 'omits timestamp by default' {
        Write-Message 'hello' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { if ($_.MessageData -is [string]) { $_.MessageData } else { $_.MessageData.Message } }) -join ''
        $text | Should -Not -Match '\d{2}[.:]\d{2}[.:]\d{2}[.:]\d{3}'
    }

    It 'omits header with -NoHeader' {
        Write-Message 'bare' -NoHeader -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { if ($_.MessageData -is [string]) { $_.MessageData } else { $_.MessageData.Message } }) -join ''
        $text | Should -Not -Match '\['
        $text | Should -Match 'bare'
    }
}
