Describe 'Write-InformationColored' {
    It 'writes to the information stream' {
        Write-InformationColored 'hello' -InformationVariable iv -InformationAction SilentlyContinue
        $iv | Should -HaveCount 1
        $iv[0].MessageData.Message | Should -Be 'hello'
        $iv[0].Tags | Should -Contain 'PSHOST'
    }

    It 'applies foreground color' {
        Write-InformationColored 'test' -ForegroundColor Green -InformationVariable iv -InformationAction SilentlyContinue
        $iv[0].MessageData.ForegroundColor | Should -Be 'Green'
    }

    It 'applies background color' {
        Write-InformationColored 'test' -BackgroundColor DarkBlue -InformationVariable iv -InformationAction SilentlyContinue
        $iv[0].MessageData.BackgroundColor | Should -Be 'DarkBlue'
    }

    It 'supports NoNewline' {
        Write-InformationColored 'test' -NoNewline -InformationVariable iv -InformationAction SilentlyContinue
        $iv[0].MessageData.NoNewline | Should -BeTrue
    }
}
