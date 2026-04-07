<#
.SYNOPSIS
    Asserts that az CLI is installed and authenticated.
.DESCRIPTION
    Checks that az is on PATH and that a session is active (az account show
    returns successfully). Throws with a clear message if either check fails.
.EXAMPLE
    Assert-AzCliConnected
#>
function Assert-AzCliConnected {
    [CmdletBinding()]
    param()

    Assert-Command az -ErrorText 'az CLI is not installed. Run Install-AzCli or install it manually.'

    $result = Invoke-CliCommand 'az account show --output json' -PassThru -NoAssert -Silent
    if ($result.ExitCode -ne 0) {
        throw 'az CLI is not authenticated. Run Connect-AzCli first.'
    }
}
