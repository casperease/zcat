Describe 'Write-Header' {
    BeforeAll {
        function script:StripAnsi ([string]$Text) { $Text -replace '\e\[[0-9;]*m', '' }
    }

    Context 'Curved (default)' {
        It 'renders box with message' {
            Write-Header 'test' -Width 20 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
            $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
            $text | Should -Match '╭──'
            $text | Should -Match '│ test'
            $text | Should -Match '╰──'
        }

        It 'renders single top line without message' {
            Write-Header -Width 20 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
            $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
            $text | Should -Match '╭──'
            $text | Should -Not -Match '│'
        }
    }

    Context 'Stars' {
        It 'renders stars with message' {
            Write-Header 'test' -Style Stars -Width 20 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
            $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
            $text | Should -Match '^\*{20}'
            $text | Should -Match '\* test'
        }

        It 'renders single star line without message' {
            Write-Header -Style Stars -Width 20 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
            $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
            $text | Should -Match '^\*{20}$'
        }
    }

    It 'applies foreground color' {
        Write-Header 'colored' -ForegroundColor Cyan -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $raw = $iv | ForEach-Object { $_.MessageData.Message } | Out-String
        $raw | Should -Match '\e\[96m'
    }
}
