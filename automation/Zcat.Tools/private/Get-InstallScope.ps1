<#
.SYNOPSIS
    Returns the install scope of a tool based on its binary location.
.DESCRIPTION
    Determines whether a tool is installed in user-space or machine-wide
    by inspecting the binary path. Returns 'user', 'machine', or 'unknown'.
.PARAMETER Config
    Tool configuration hashtable from Get-ToolConfig / tools.yml.
.PARAMETER Location
    Full path to the tool binary (from Get-Command .Source).
#>
function Get-InstallScope {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config,
        [Parameter(Mandatory)]
        [string] $Location
    )

    # Script-installed tools (e.g., Dotnet via dotnet-install scripts).
    if ($Config.ScriptInstall) {
        $userDir = Get-ScriptInstallDir -Config $Config
        if ($Location -like "$userDir*") {
            return 'user'
        }
        return 'machine'
    }

    if ($IsWindows) {
        # User-space installs go under LOCALAPPDATA, APPDATA, or USERPROFILE
        foreach ($root in @($env:LOCALAPPDATA, $env:APPDATA, $env:USERPROFILE) | Where-Object { $_ }) {
            if ($Location -like "$root*") {
                return 'user'
            }
        }
        return 'machine'
    }

    if ($IsMacOS) {
        # brew installs to /opt/homebrew/ or /usr/local/ — user-space
        return 'user'
    }

    if ($IsLinux) {
        # pip --user and user-local tools live under ~/.local/
        $homeLocal = Join-Path $HOME '.local'
        if ($Location -like "$homeLocal*") {
            return 'user'
        }
        # apt-get, system pip, etc. → machine
        return 'machine'
    }

    'unknown'
}
