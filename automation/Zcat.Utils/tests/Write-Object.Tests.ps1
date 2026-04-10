Describe 'Write-Object' {
    BeforeAll {
        function script:StripAnsi ([string]$Text) { $Text -replace '\e\[[0-9;]*m', '' }
    }

    It 'shows type info in header for a string' {
        Write-Object 'hello' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
        $text | Should -Match '\[String\] Length: 5'
    }

    It 'renders a string value directly' {
        Write-Object 'hello' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
        $text | Should -Match 'hello'
    }

    It 'shows type info in header for a number' {
        Write-Object 42 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
        $text | Should -Match 'Int32'
    }

    It 'renders hashtable as YAML with nesting' {
        Write-Object @{ A = 1; B = @{ C = 3 } } -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
        $text | Should -Match 'A: 1'
        $text | Should -Match 'C: 3'
    }

    It 'renders PSCustomObject as YAML' {
        $obj = [pscustomobject]@{ Name = 'test'; Value = 42 }
        Write-Object $obj -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
        $text | Should -Match 'Name: test'
    }

    It 'renders array of complex objects as YAML' {
        $arr = @([pscustomobject]@{X=1}, [pscustomobject]@{X=2})
        Write-Object $arr -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
        $text | Should -Match '\[Array\] Count: 2'
    }

    It 'throws on null' {
        { Write-Object $null } | Should -Throw
    }

    It 'shows name and type in header' {
        Write-Object 'x' -Name 'MyLabel' -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
        $text | Should -Match 'MyLabel'
        $text | Should -Match '\[String\]'
        $text | Should -Match '╭──'
    }

    It 'accepts pipeline input' {
        'test' | Write-Object -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $iv | Should -Not -BeNullOrEmpty
    }

    It 'renders ErrorRecord without throwing' {
        $err = try { throw 'boom' } catch { $_ }
        Write-Object $err -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
        $text | Should -Match 'ErrorRecord'
    }

    It 'renders object with throwing property using not-rendered marker' {
        $obj = [PSCustomObject]@{ Good = 'ok' }
        $obj | Add-Member -MemberType ScriptProperty -Name Bad -Value { throw 'nope' }
        Write-Object $obj -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
        $text | Should -Match 'Good: ok'
        $text | Should -Match '\[not rendered\]'
    }

    It 'renders array containing ErrorRecords without throwing' {
        $err = try { throw 'boom' } catch { $_ }
        $arr = @([PSCustomObject]@{ Name = 'a' }, $err)
        Write-Object $arr -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { StripAnsi $_.MessageData.Message }) -join "`n"
        $text | Should -Match '\[Array\] Count: 2'
    }
}
