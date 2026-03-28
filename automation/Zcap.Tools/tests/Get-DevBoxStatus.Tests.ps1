Describe 'Get-DevBoxStatus' {
    It 'is exported and callable' {
        Get-Command Get-DevBoxStatus | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-DevBoxStatus integration' -Tag 'L2' {
    It 'returns objects with expected properties' {
        $results = Get-DevBoxStatus
        $results | Should -Not -BeNullOrEmpty
        $first = $results | Select-Object -First 1
        $first.PSObject.Properties.Name | Should -Contain 'Tool'
        $first.PSObject.Properties.Name | Should -Contain 'Locked'
        $first.PSObject.Properties.Name | Should -Contain 'Installed'
        $first.PSObject.Properties.Name | Should -Contain 'Status'
        $first.PSObject.Properties.Name | Should -Contain 'Location'
        $first.PSObject.Properties.Name | Should -Contain 'Manager'
        $first.PSObject.Properties.Name | Should -Contain 'Scope'
        $first.PSObject.Properties.Name | Should -Contain 'Action'
    }
}
