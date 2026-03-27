Describe 'Write-CallStack' {
    It 'outputs call stack information' {
        Write-CallStack -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $iv | Should -Not -BeNullOrEmpty
    }

    It 'includes line numbers in output' {
        Write-CallStack -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { if ($_.MessageData -is [string]) { $_.MessageData } else { $_.MessageData.Message } }) -join "`n"
        $text | Should -Match ':\d+'
    }
}
