<#
.SYNOPSIS
    Installs a tool using the platform package manager.
.DESCRIPTION
    Uses winget on Windows, brew on macOS, and apt-get on Linux.
.PARAMETER Tool
    The tool name as defined in Get-ToolConfig.
.PARAMETER Version
    Version override. Defaults to the locked version.
#>
function Install-Tool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Tool,

        [string] $Version
    )

    $config = Get-ToolConfig -Tool $Tool
    if (-not $Version) { $Version = $config.Version }

    if ($IsWindows) {
        Assert-Command winget
        $packageId = $config.WingetId -f $Version
        Invoke-CliCommand "winget install --id $packageId --accept-source-agreements --accept-package-agreements --silent"
    }
    elseif ($IsMacOS) {
        Assert-Command brew
        $formula = $config.BrewFormula -f $Version
        Invoke-CliCommand "brew install $formula"
    }
    elseif ($IsLinux) {
        Assert-Command apt-get
        $package = $config.AptPackage -f $Version
        Invoke-CliCommand "sudo apt-get update -qq"
        Invoke-CliCommand "sudo apt-get install -y $package"
    }
    else {
        throw "Unsupported platform for tool installation"
    }

    Assert-Command $config.Command -ErrorText "$Tool was installed but '$($config.Command)' is not on PATH. You may need to restart your shell."
    Write-Information "$Tool $Version installed successfully"
}
