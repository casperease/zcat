Describe 'Uninstall-Chocolatey' {
    It 'is exported and callable' {
        Get-Command Uninstall-Chocolatey | Should -Not -BeNullOrEmpty
    }

    It 'has no mandatory parameters' {
        $params = (Get-Command Uninstall-Chocolatey).Parameters
        $mandatory = $params.Values | Where-Object {
            $_.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }
        }
        $mandatory | Should -BeNullOrEmpty
    }
}
