Describe 'Write-Array' {
    It 'outputs header with name' {
        Write-Array @('a') -Name 'Items' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $iv[0].MessageData.Message | Should -Be '--- Items ---'
    }

    It 'outputs each array element' {
        Write-Array @('one', 'two', 'three') -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $messages = $iv | ForEach-Object { $_.MessageData.Message }
        $messages | Should -Contain 'one'
        $messages | Should -Contain 'two'
        $messages | Should -Contain 'three'
    }

    It 'outputs footer separator' {
        Write-Array @('a') -Name 'X' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $last = ($iv | Select-Object -Last 1).MessageData.Message
        $last | Should -Match '^-+$'
    }

    It 'handles empty array' {
        Write-Array @() -Name 'Empty' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $iv | Should -HaveCount 2  # header + footer only
    }
}
