<#
.SYNOPSIS
    Installs a pip-managed tool.
.DESCRIPTION
    Private helper for Install-Poetry and Install-AzCli. Mirrors
    Install-Tool's contract but uses pip instead of platform package
    managers. Handles idempotency, scope validation, and Force.
.PARAMETER Tool
    The tool name as defined in Get-ToolConfig.
.PARAMETER Version
    Version override. Defaults to the locked version.
.PARAMETER Force
    Automatically uninstall the wrong version before installing the correct one.
#>
function Install-PipTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Tool,
        [string] $Version,
        [switch] $Force
    )

    $config = Get-ToolConfig -Tool $Tool
    Assert-NotNullOrWhitespace $config.PipPackage -ErrorText "$Tool has no PipPackage in tools.yml — cannot install via pip"

    if (-not $Version) { $Version = $config.Version }

    # Dependency: pip-managed tools require Python
    Assert-Tool 'Python'

    # Scope check: pip writes to Python's Scripts directory. If Python is
    # machine-wide, that directory is read-only without admin.
    $pythonConfig = Get-ToolConfig -Tool 'Python'
    $pythonLocation = (Get-Command python).Source
    $scope = Get-InstallScope -Config $pythonConfig -Location $pythonLocation
    if ($scope -eq 'machine' -and -not (Test-IsAdministrator)) {
        throw "Python is installed machine-wide at '$pythonLocation'. " +
              "pip cannot write to its Scripts directory without admin. " +
              "Either run as Administrator, or uninstall Python and run Install-Python to install user-scope."
    }

    # Idempotent: skip if already installed at the correct version
    if (Test-Command $config.Command) {
        $installed = Get-ToolVersion -Config $config

        if ($installed -and $installed.StartsWith($Version)) {
            Write-Message "$Tool $Version is already installed"
            return
        }

        if (-not $installed) {
            Write-Verbose "Could not parse version from '$((Get-Command $config.Command).Source)' — treating as not installed"
        }
        elseif ($Force) {
            Write-Verbose "$Tool $installed found — uninstalling before installing $Version"
            Invoke-Pip "uninstall $($config.PipPackage) -y"
        }
        else {
            $location = (Get-Command $config.Command).Source
            throw "$Tool version mismatch: expected $Version.x, found $installed at '$location'. Run Install-$Tool -Force to replace, or uninstall manually."
        }
    }

    Invoke-Pip "install -q $($config.PipPackage)==$Version.*"

    # Refresh PATH — merge registry entries into current session PATH.
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
        Write-Message "$Tool $actualVersion installed successfully"
    }
    elseif ($actualVersion) {
        Write-Message "$Tool installed but version $actualVersion does not match expected $Version.x — package manager may have installed a different version"
    }
    else {
        Write-Message "$Tool installed but could not verify version"
    }
}
