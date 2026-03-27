<#
.SYNOPSIS
    Asserts that a command exists on the system.
.PARAMETER Command
    The command name to look up via Get-Command.
.PARAMETER ErrorText
    Custom error message. Defaults to '<Command> is not installed'.
.EXAMPLE
    Assert-Command 'git'
#>
function Assert-Command {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Command,

        [string] $ErrorText
    )

    if (-not (Test-Command $Command)) {
        if (-not $ErrorText) { $ErrorText = "$Command is not installed" }
        throw $ErrorText
    }
}
