Describe 'Write-Header' {
    BeforeAll {
        function script:StripAnsi ([string]$Text) { $Text -replace '\e\[[0-9;]*m', '' }
    }

    It 'renders box top with message' {
        Write-Header 'test' -Width 20 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
        $text | Should -Match '╭──'
        $text | Should -Match '│ test'
    }

    It 'renders single top line without message' {
        Write-Header -Width 20 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
        $text | Should -Match '╭──'
        $text | Should -Not -Match '│'
    }

    It 'uses specified width' {
        Write-Header 'x' -Width 10 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
        $text | Should -Match '╭─{8}╮'
    }

    It 'applies foreground color' {
        Write-Header 'colored' -ForegroundColor Cyan -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $raw = $iv | ForEach-Object { $_.MessageData.Message } | Out-String
        $raw | Should -Match '\e\[96m'
    }
}
