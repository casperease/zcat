<#
.SYNOPSIS
    Removes the globally upgraded npm, reverting to the Node.js bundled version.
.DESCRIPTION
    Undoes Install-Npm by removing the global npm override. The npm version
    that shipped with Node.js remains available. Idempotent — skips if npm
    is not installed or Node.js is not available.
.EXAMPLE
    Uninstall-Npm
#>
function Uninstall-Npm {
    [CmdletBinding()]
    param()

    $config = Get-ToolConfig -Tool 'Npm'

    if (-not (Test-Command $config.Command)) {
        Write-Message "npm is not installed — nothing to do"
        return
    }

    if (-not (Test-Command node)) {
        Write-Message "Node.js is not available — npm already gone"
        return
    }

    # Remove the global npm override installed by Install-Npm.
    # The version bundled with Node.js remains available.
    Invoke-CliCommand "npm uninstall -g npm" -NoAssert
    Write-Message "npm global override removed"
}
