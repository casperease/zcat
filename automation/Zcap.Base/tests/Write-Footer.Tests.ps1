Describe 'Write-Footer' {
    BeforeAll {
        function script:StripAnsi ([string]$Text) { $Text -replace '\e\[[0-9;]*m', '' }
    }

    It 'Curved renders closing bottom line' {
        Write-Footer -Width 20 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        StripAnsi $iv[0].MessageData.Message | Should -Match '╰─{18}╯'
    }

    It 'Stars renders star line' {
        Write-Footer -Style Stars -Width 20 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        StripAnsi $iv[0].MessageData.Message | Should -Match '^\*{20}$'
    }

    It 'applies foreground color' {
        Write-Footer -ForegroundColor Cyan -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $iv[0].MessageData.Message | Should -Match '\e\[96m'
    }
}
