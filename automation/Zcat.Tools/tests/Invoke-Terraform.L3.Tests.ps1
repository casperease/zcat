Describe 'Invoke-Terraform' -Tag 'L3' {
    BeforeAll {
        $script:available = Test-Tool 'Terraform'
    }

    It 'reports version as JSON with accessible properties' {
        if (-not $script:available) { Set-ItResult -Skipped -Because 'Terraform not available'; return }
        $result = Invoke-Terraform 'version -json' -PassThru -Silent
        $result.ExitCode | Should -Be 0
        $version = $result.Output | ConvertFrom-Json
        $version.terraform_version | Should -Match '\d+\.\d+'
    }
}
