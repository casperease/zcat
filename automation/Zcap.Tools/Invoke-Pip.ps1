<#
.SYNOPSIS
    Runs pip with the given arguments.
.DESCRIPTION
    Asserts Python is available and usable before executing.
    Uses python -m pip to ensure the correct pip is used.
    For install commands, also asserts version match and checks scope.
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

        # Verify python is real (not a Windows Store stub that returns no version).
        # A stub means no real Python is installed — pip packages can't exist either.
        $pythonConfig = Get-ToolConfig -Tool 'Python'
        $raw = Invoke-CliCommand $pythonConfig.VersionCommand -PassThru -NoAssert -Silent 2>$null
        if (-not ($raw -match $pythonConfig.VersionPattern)) {
            if ($Arguments -match '^uninstall\b') {
                Write-Message "Python is not usable (Store stub?) — skipping pip uninstall"
                return
            }
            throw "Python is not usable — 'python --version' returned nothing. " +
                  "This is likely the Windows Store stub. Run Install-Python first."
        }

        if ($Arguments -match '^install\b') {
            # Full version check for install — we need the right Python
            Assert-ToolVersion -Tool 'Python'

            # pip writes to Python's Scripts directory. If Python is machine-wide,
            # that directory is read-only without admin → access denied.
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
