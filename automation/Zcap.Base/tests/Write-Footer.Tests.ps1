Describe 'Write-Footer' {
    BeforeAll {
        function script:StripAnsi ([string]$Text) { $Text -replace '\e\[[0-9;]*m', '' }
    }

    It 'renders closing bottom line' {
        Write-Footer -Width 20 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = StripAnsi $iv[0].MessageData.Message
        $text | Should -Match '╰──'
        $text | Should -Match '╯'
    }

    It 'uses specified width' {
        Write-Footer -Width 10 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = StripAnsi $iv[0].MessageData.Message
        $text | Should -Match '╰─{8}╯'
    }

    It 'applies foreground color' {
        Write-Footer -ForegroundColor Cyan -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $raw = $iv[0].MessageData.Message
        $raw | Should -Match '\e\[96m'
    }
}
