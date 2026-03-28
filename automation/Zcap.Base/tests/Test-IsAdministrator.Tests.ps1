Describe 'Test-IsAdministrator' {
    It 'returns a boolean' {
        Test-IsAdministrator | Should -BeOfType [bool]
    }
}
