<#
.SYNOPSIS
    Runs pip with the given arguments.
.DESCRIPTION
    Asserts Python is available before executing.
    Uses python -m pip to ensure the correct pip is used.
    For install commands, asserts version match and checks scope.
.PARAMETER Arguments
    Arguments to pass to pip.
.PARAMETER PassThru
    Capture and return the output.
.PARAMETER NoAssert
    Skip exit code assertion.
.PARAMETER DryRun
    Return the command string without executing. Used for testing.
.EXAMPLE
    Invoke-Pip 'install requests'
.EXAMPLE
    Invoke-Pip 'install requests' -DryRun
#>
function Invoke-Pip {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Arguments,
        [switch] $PassThru,
        [switch] $NoAssert,
        [switch] $DryRun
    )

    Assert-NotNullOrWhitespace $Arguments -ErrorText 'Arguments cannot be empty'

    if (-not $DryRun) {
        Assert-Command python

        if ($Arguments -match '^install\b') {
            Assert-ToolVersion -Tool 'Python'

            # pip writes to Python's Scripts directory. If Python is machine-wide,
            # that directory is read-only without admin → access denied.
            $pythonConfig = Get-ToolConfig -Tool 'Python'
            $pythonLocation = (Get-Command python).Source
            $scope = Get-InstallScope -Config $pythonConfig -Location $pythonLocation
            if ($scope -eq 'machine' -and -not (Test-IsAdministrator)) {
                throw "Python is installed machine-wide at '$pythonLocation'. " +
                      "pip cannot write to its Scripts directory without admin. " +
                      "Either run as Administrator, or uninstall Python and run Install-Python to install user-scope."
            }
        }
    }

    Invoke-CliCommand "python -m pip $Arguments" -PassThru:$PassThru -NoAssert:$NoAssert -DryRun:$DryRun
}
