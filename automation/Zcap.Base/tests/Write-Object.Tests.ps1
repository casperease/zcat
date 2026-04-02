Describe 'Write-Object' {
    BeforeAll {
        function script:StripAnsi ([string]$Text) { $Text -replace '\e\[[0-9;]*m', '' }
    }

    It 'shows type info for a string' {
        Write-Object 'hello' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        StripAnsi $iv[0].MessageData.Message | Should -Match '\[String\] Length: 5'
    }

    It 'renders a string value directly' {
        Write-Object 'hello' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        StripAnsi $iv[1].MessageData.Message | Should -Be 'hello'
    }

    It 'shows type info for a number' {
        Write-Object 42 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        StripAnsi $iv[0].MessageData.Message | Should -Match 'Int32'
    }

    It 'renders hashtable as YAML with nesting' {
        Write-Object @{ A = 1; B = @{ C = 3 } } -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $messages = $iv | ForEach-Object { StripAnsi $_.MessageData.Message }
        $yaml = $messages -join "`n"
        $yaml | Should -Match 'A: 1'
        $yaml | Should -Match 'C: 3'
    }

    It 'renders PSCustomObject as YAML' {
        $obj = [pscustomobject]@{ Name = 'test'; Value = 42 }
        Write-Object $obj -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $messages = $iv | ForEach-Object { StripAnsi $_.MessageData.Message }
        ($messages -join "`n") | Should -Match 'Name: test'
    }

    It 'renders array of complex objects as YAML' {
        $arr = @([pscustomobject]@{X=1}, [pscustomobject]@{X=2})
        Write-Object $arr -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $messages = $iv | ForEach-Object { StripAnsi $_.MessageData.Message }
        $messages[0] | Should -Match '\[Array\] Count: 2'
    }

    It 'handles null' {
        Write-Object $null -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        StripAnsi $iv[0].MessageData.Message | Should -Be '[null]'
    }

    It 'shows name label when provided' {
        Write-Object 'x' -Name 'MyLabel' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        StripAnsi $iv[0].MessageData.Message | Should -Be '--- MyLabel ---'
    }

    It 'accepts pipeline input' {
        'test' | Write-Object -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $iv | Should -Not -BeNullOrEmpty
    }
}
