Describe 'Write-Header' {
    BeforeAll {
        function script:StripAnsi ([string]$Text) { $Text -replace '\e\[[0-9;]*m', '' }
    }

    It 'wraps message with separator lines' {
        Write-Header 'test' -Width 10 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = StripAnsi ($iv | ForEach-Object { $_.MessageData.Message } | Out-String)
        $text | Should -Match '\*{10}'
        $text | Should -Match '\* test'
    }

    It 'outputs single separator when no message' {
        Write-Header -Width 10 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = StripAnsi ($iv | ForEach-Object { $_.MessageData.Message } | Out-String)
        $text | Should -Match '^\*{10}'
        $text | Should -Not -Match '\* '
    }

    It 'uses specified width for separators' {
        Write-Header 'x' -Width 5 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = StripAnsi ($iv | ForEach-Object { $_.MessageData.Message } | Out-String)
        $text | Should -Match '\*{5}'
    }

    It 'applies foreground color' {
        Write-Header 'colored' -ForegroundColor Cyan -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $raw = $iv | ForEach-Object { $_.MessageData.Message } | Out-String
        # Cyan = ANSI [96m
        $raw | Should -Match '\e\[96m'
    }
}
