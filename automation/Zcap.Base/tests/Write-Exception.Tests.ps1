Describe 'Write-Exception' {
    BeforeAll {
        Mock Test-IsRunningInPipeline { $false }
    }

    It 'displays exception type and message from an ErrorRecord' {
        try { throw [System.InvalidOperationException]::new('test error') } catch { $null }
        Write-Exception $global:Error[0] -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { if ($_.MessageData -is [string]) { $_.MessageData } else { $_.MessageData.Message } }) -join "`n"
        $text | Should -Match 'InvalidOperationException'
        $text | Should -Match 'test error'
    }

    It 'shows inner exceptions' {
        try { throw [System.InvalidOperationException]::new('outer', [System.IO.FileNotFoundException]::new('inner')) } catch { $null }
        Write-Exception $global:Error[0] -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { if ($_.MessageData -is [string]) { $_.MessageData } else { $_.MessageData.Message } }) -join "`n"
        $text | Should -Match 'inner'
        $text | Should -Match 'FileNotFoundException'
    }

    It 'falls back to $global:Error when no parameter given' {
        try { throw 'fallback error' } catch { $null }
        Write-Exception -GlobalErrorIndex 0 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $text = ($iv | ForEach-Object { if ($_.MessageData -is [string]) { $_.MessageData } else { $_.MessageData.Message } }) -join "`n"
        $text | Should -Match 'fallback error'
    }

    It 'produces no output when no error exists' {
        $savedErrors = $global:Error.Clone()
        $global:Error.Clear()
        Write-Exception -GlobalErrorIndex 0 -InformationVariable iv -InformationAction SilentlyContinue 6>&1 | Out-Null
        $iv | Should -BeNullOrEmpty
        $savedErrors | ForEach-Object { $global:Error.Add($_) }
    }
}
