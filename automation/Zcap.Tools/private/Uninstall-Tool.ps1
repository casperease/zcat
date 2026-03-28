<#
.SYNOPSIS
    Uninstalls a tool using the platform package manager.
.DESCRIPTION
    Uses winget on Windows, brew on macOS, and apt-get on Linux.
    Skips if the tool is not installed.
.PARAMETER Tool
    The tool name as defined in Get-ToolConfig.
.PARAMETER Version
    Version override. Defaults to the locked version.
#>
function Uninstall-Tool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Tool,

        [string] $Version
    )

    $config = Get-ToolConfig -Tool $Tool
    if (-not $Version) { $Version = $config.Version }

    # Idempotent: skip if not installed
    if (-not (Test-Command $config.Command)) {
        Write-Message "$Tool is not installed — nothing to do"
        return
    }

    if ($IsWindows) {
        Assert-Command winget
        $packageId = $config.WingetId -f $Version
        Invoke-CliCommand "winget uninstall --id $packageId --silent"
    }
    elseif ($IsMacOS) {
        Assert-Command brew
        $formula = $config.BrewFormula -f $Version
        Invoke-CliCommand "brew uninstall $formula"
    }
    elseif ($IsLinux) {
        Assert-Command apt-get
        $package = $config.AptPackage -f $Version
        Invoke-CliCommand "sudo apt-get remove -y $package"
    }
    else {
        throw "Unsupported platform for tool uninstallation"
    }

    Write-Information "$Tool $Version uninstalled"
}
