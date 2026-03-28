<#
.SYNOPSIS
    Runs pip with the given arguments.
.DESCRIPTION
    Asserts Python version matches the locked version before executing.
    Uses python -m pip to ensure the correct pip is used.
    Fails fast if Python is installed machine-wide — pip install/uninstall
    would fail with access denied on the protected Scripts directory.
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
        Assert-ToolVersion -Tool 'Python'

        # pip writes to Python's Scripts directory. If Python is machine-wide,
        # that directory is read-only without admin → access denied.
        # Fail fast with a clear message instead of a cryptic pip error.
        if ($Arguments -match '^(install|uninstall)\b') {
            $pythonLocation = (Get-Command python).Source
            $pythonConfig = Get-ToolConfig -Tool 'Python'
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
