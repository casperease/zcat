Describe 'Write-InformationColored' {
    It 'writes message to the information stream' {
        Write-InformationColored 'hello' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $iv | Should -HaveCount 1
        $iv[0].MessageData.Message | Should -Match 'hello'
    }

    It 'wraps text in ANSI escape codes when color specified' {
        Write-InformationColored 'test' -ForegroundColor Red -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = $iv[0].MessageData.Message
        $text | Should -Match '^\e\[91m'
        $text | Should -Match '\e\[0m$'
        $text | Should -Match 'test'
    }

    It 'does not add ANSI codes when no color specified' {
        Write-InformationColored 'plain' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $iv[0].MessageData.Message | Should -Be 'plain'
    }

    It 'maps Cyan to correct ANSI code' {
        Write-InformationColored 'x' -ForegroundColor Cyan -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $iv[0].MessageData.Message | Should -Match '^\e\[96m'
    }
}
