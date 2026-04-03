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
        $location = (Get-Command $config.Command).Source

        $installed = Get-ToolVersion -Config $config

        if ($installed -and $installed.StartsWith($Version)) {
            Write-Message "$Tool $Version is already installed"
            return
        }

        if (-not $installed) {
            # Version unparseable (e.g., Windows Store stub) — not a real installation, skip to install
            Write-Verbose "Could not parse version from '$location' — treating as not installed"
        }
        elseif ($Force) {
            if (Test-IsRunningInPipeline) {
                Write-Message "$Tool $installed found at '$location' — skipping uninstall in CI, installing over it"
            }
            else {
                Write-Verbose "$Tool $installed found at '$location' — uninstalling before installing $Version"
                Uninstall-Tool -Tool $Tool
            }
        }
        else {
            throw "$Tool version mismatch: expected $Version.x, found $installed at '$location'. Run Install-$Tool -Force to replace, or uninstall manually."
        }
    }

    if ($IsWindows) {
        Assert-NotNullOrWhitespace $config.WingetId -ErrorText "$Tool has no WingetId — use Install-$Tool directly"
        Assert-Command winget
        $packageId = $config.WingetId -f $Version

        # --force: winget may see a Store stub or stale alias and report "already installed"
        # even though no real installation exists. Force ensures it always installs.
        if ($config.WingetScope -eq 'user') {
            Invoke-CliCommand "winget install --id $packageId --scope user --accept-source-agreements --accept-package-agreements --silent --force"
        }
        else {
            Assert-IsAdministrator -ErrorText "Install-$Tool on Windows requires Administrator (winget machine-scope). Run as Administrator or install $Tool manually."
            Invoke-CliCommand "winget install --id $packageId --accept-source-agreements --accept-package-agreements --silent --force"
        }
    }
    elseif ($IsMacOS) {
        Assert-NotNullOrWhitespace $config.BrewFormula -ErrorText "$Tool has no BrewFormula — use Install-$Tool directly"
        Assert-Command brew
        $formula = $config.BrewFormula -f $Version
        Invoke-CliCommand "brew install $formula"
    }
    elseif ($IsLinux) {
        Assert-NotNullOrWhitespace $config.AptPackage -ErrorText "$Tool has no AptPackage — use Install-$Tool directly"
        # Linux package installation via apt-get requires root. No user-space
        # package-manager alternative exists without adding a new tool dependency.
        # Two paths to eliminate this requirement:
        #   Option A: Vendor the uv binary (astral.sh/uv, ~25 MB static Rust binary).
        #             uv python install <ver> is fully user-space on all platforms.
        #             Also gives isolated tool installs (uv tool install azure-cli).
        #   Option B: Upgrade Python to 3.12+ in tools.yml. Fixes the Windows UAC
        #             issue (3.11 burn installer) but Linux still needs admin here.
        Assert-IsAdministrator -ErrorText "Install-$Tool on Linux requires root (apt-get). Run as root or install $Tool manually."
        Assert-Command apt-get
        $package = $config.AptPackage -f $Version
        Invoke-CliCommand "sudo apt-get update -qq"
        Invoke-CliCommand "sudo apt-get install -y $package"
    }
    else {
        throw "Unsupported platform for tool installation"
    }

    # Refresh PATH — merge registry entries into current session PATH.
    # Replaces the old approach that dropped session-only entries (dotnet tools,
    # conda, etc.). New entries from the installer are added; existing entries preserved.
    if ($IsWindows) {
        $machinePath = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
        $userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
        $registryPaths = ($userPath, $machinePath | ForEach-Object { $_ -split ';' }) |
            Where-Object { $_ -ne '' }

        $currentPaths = $env:PATH -split ';' | Where-Object { $_ -ne '' }
        $seen = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]$currentPaths,
            [System.StringComparer]::OrdinalIgnoreCase
        )
        $newPaths = foreach ($p in $registryPaths) {
            if ($seen.Add($p)) { $p }
        }
        $env:PATH = (@($currentPaths) + @($newPaths)) -join ';'
        Write-Verbose 'Refreshed PATH from registry (merged with session)'
    }

    Assert-Command $config.Command -ErrorText "$Tool was installed but '$($config.Command)' is not on PATH. You may need to restart your shell."

    # Verify the actual installed version matches what we asked for.
    $actualVersion = Get-ToolVersion -Config $config

    if ($actualVersion -and $actualVersion.StartsWith($Version)) {
        Write-Information "$Tool $actualVersion installed successfully"
    }
    elseif ($actualVersion) {
        Write-Message "$Tool installed but version $actualVersion does not match expected $Version.x — package manager may have installed a different version"
    }
    else {
        Write-Message "$Tool installed but could not verify version"
    }
}
