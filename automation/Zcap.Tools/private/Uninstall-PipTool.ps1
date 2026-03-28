<#
.SYNOPSIS
    Uninstalls a pip-managed tool.
.DESCRIPTION
    Private helper for Uninstall-Poetry and Uninstall-AzCli. Mirrors
    Uninstall-Tool's contract but uses pip instead of platform package
    managers. Idempotent — skips if the tool or Python is not installed.
.PARAMETER Tool
    The tool name as defined in Get-ToolConfig.
#>
function Uninstall-PipTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Tool
    )

    $config = Get-ToolConfig -Tool $Tool
    Assert-NotNullOrWhitespace $config.PipPackage -ErrorText "$Tool has no PipPackage in tools.yml — cannot uninstall via pip"

    # Idempotent: skip if tool is not installed
    if (-not (Test-Command $config.Command)) {
        Write-Message "$Tool is not installed — nothing to do"
        return
    }

    # Python required for pip uninstall. Test-Tool checks both presence
    # and functionality — filters out Windows Store stubs.
    if (-not (Test-Tool 'Python')) {
        Write-Message "Python is not available — pip packages already gone"
        return
    }

    # Call pip directly — Invoke-Pip asserts tool version which is unnecessary
    # and can fail during uninstall (e.g., wrong version during teardown).
    Invoke-CliCommand "python -m pip uninstall $($config.PipPackage) -y" 2>$null
    Write-Message "$Tool uninstalled"
}
