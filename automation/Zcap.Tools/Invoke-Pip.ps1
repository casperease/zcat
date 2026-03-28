<#
.SYNOPSIS
    Runs pip with the given arguments.
.DESCRIPTION
    Asserts Python version matches the locked version before executing.
    Uses python -m pip to ensure the correct pip is used.
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
    }

    Invoke-CliCommand "python -m pip $Arguments" -PassThru:$PassThru -NoAssert:$NoAssert -DryRun:$DryRun
}
