<#
.SYNOPSIS
    Resolves the install directory for a script-installed tool.
.DESCRIPTION
    Returns the platform-appropriate install directory for tools with
    ScriptInstall: true. Checks config overrides first, then falls back
    to sensible defaults per platform:
      Windows: LOCALAPPDATA\<WindowsInstallDir or Command>
      Unix:    HOME/<UnixInstallDir or .Command>
.PARAMETER Config
    Tool configuration hashtable from Get-ToolConfig / tools.yml.
#>
function Get-ScriptInstallDir {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    if ($IsWindows) {
        $relative = $Config.WindowsInstallDir ?? $Config.Command
        return Join-Path $env:LOCALAPPDATA $relative
    }

    $relative = $Config.UnixInstallDir ?? ".$($Config.Command)"
    Join-Path $HOME $relative
}
