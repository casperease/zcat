Describe 'Write-Hashtable' {
    It 'outputs header with name' {
        Write-Hashtable @{ A = 1 } -Name 'Params' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $iv[0].MessageData.Message | Should -Be '--- Params ---'
    }

    It 'outputs key = value pairs' {
        Write-Hashtable @{ Path = './out'; Force = $true } -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $messages = $iv | ForEach-Object { $_.MessageData.Message }
        $messages | Should -Contain 'Force = True'
        $messages | Should -Contain 'Path = ./out'
    }

    It 'sorts keys alphabetically' {
        Write-Hashtable @{ Zebra = 1; Apple = 2 } -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $messages = $iv | ForEach-Object { $_.MessageData.Message }
        $messages[1] | Should -Match '^Apple'
        $messages[2] | Should -Match '^Zebra'
    }

    It 'outputs footer separator' {
        Write-Hashtable @{ A = 1 } -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $last = ($iv | Select-Object -Last 1).MessageData.Message
        $last | Should -Match '^-+$'
    }

    It 'works via Write-Splat alias' {
        # Intentionally testing the alias — use full cmdlet name via Get-Alias
        $cmd = Get-Alias Write-Splat
        $cmd | Should -Not -BeNullOrEmpty
        & $cmd @{ X = 1 } -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $iv | Should -Not -BeNullOrEmpty
    }
}
