<#
.SYNOPSIS
    Installs a tool using the platform package manager.
.DESCRIPTION
    Uses winget on Windows, brew on macOS, and apt-get on Linux.
    Idempotent — skips if already installed at the correct version.
    If the wrong version is found, -Force uninstalls and reinstalls.
    Without -Force, throws with instructions.
.PARAMETER Tool
    The tool name as defined in Get-ToolConfig.
.PARAMETER Version
    Version override. Defaults to the locked version.
.PARAMETER Force
    Automatically uninstall the wrong version before installing the correct one.
#>
function Install-Tool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Tool,

        [string] $Version,

        [switch] $Force
    )

    $config = Get-ToolConfig -Tool $Tool
    if (-not $Version) { $Version = $config.Version }

    # Idempotent: skip if already installed at the correct version
    if (Test-Command $config.Command) {
        $raw = Invoke-CliCommand $config.VersionCommand -PassThru -NoAssert -Silent
        if ($raw -match $config.VersionPattern -and $Matches['ver'].StartsWith($Version)) {
            Write-Verbose "$Tool $Version is already installed"
            return
        }

        $installed = $Matches['ver']
        $location = (Get-Command $config.Command).Source

        if ($Force) {
            Write-Verbose "$Tool $installed found at '$location' — uninstalling before installing $Version"
            Uninstall-Tool -Tool $Tool
        }
        else {
            throw "$Tool version mismatch: expected $Version.x, found $installed at '$location'. Run Install-$Tool -Force to replace, or uninstall manually."
        }
    }

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
