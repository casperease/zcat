Describe 'Write-Header' {
    BeforeAll {
        Mock Test-IsRunningInPipeline { $false }
    }

    It 'wraps message with separator lines' {
        Write-Header 'test' -Width 10 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = $iv[0].MessageData.Message
        $text | Should -Match '^\*{10}'
        $text | Should -Match '\* test'
    }

    It 'uses specified width for separators' {
        Write-Header 'x' -Width 5 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = $iv[0].MessageData.Message
        $lines = $text -split "`n"
        $lines[0] | Should -Be ('*' * 5)
    }

    It 'applies foreground color' {
        Write-Header 'colored' -ForegroundColor Cyan -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $iv[0].MessageData.ForegroundColor | Should -Be 'Cyan'
    }
}
