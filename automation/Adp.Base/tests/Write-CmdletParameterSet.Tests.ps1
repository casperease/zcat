Describe 'Write-CmdletParameterSet' {
    BeforeAll {
        # Params are used via $MyInvocation, not directly
        function Test-DummyFunc {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
            param([string]$Name, [string]$Secret, [switch]$Force)
            Write-CmdletParameterSet $MyInvocation -HiddenKeys 'Secret' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
            $iv
        }
    }

    It 'outputs header with function name' {
        $iv = Test-DummyFunc -Name 'hello'
        $iv[0].MessageData.Message | Should -Be '--- Test-DummyFunc Parameters ---'
    }

    It 'displays bound parameter values' {
        $iv = Test-DummyFunc -Name 'hello' -Force
        $messages = $iv | ForEach-Object { $_.MessageData.Message }
        $messages | Should -Contain 'Force = True'
        $messages | Should -Contain 'Name = hello'
    }

    It 'masks hidden keys' {
        $iv = Test-DummyFunc -Name 'hello' -Secret 'password'
        $messages = $iv | ForEach-Object { $_.MessageData.Message }
        $messages | Should -Contain 'Secret = Hidden'
        $messages | Should -Not -Contain 'Secret = password'
    }

    It 'only shows bound parameters' {
        $iv = Test-DummyFunc -Name 'hello'
        $messages = ($iv | ForEach-Object { $_.MessageData.Message }) -join "`n"
        $messages | Should -Not -Match 'Secret'
        $messages | Should -Not -Match 'Force'
    }
}
