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

    # Idempotent: skip if not installed or not functional (e.g., Windows Store stub)
    if (-not (Test-Tool $Tool)) {
        Write-Message "$Tool is not installed — nothing to do"
        return
    }

    # Only uninstall tools managed by the expected package manager.
    # Use Remove-<Tool> for tools installed outside our control.
    if (-not (Test-ExpectedPackageManager -Config $config)) {
        $location = (Get-Command $config.Command).Source
        throw "$Tool at '$location' was not installed by the expected package manager. Use Remove-$Tool to handle it."
    }

    if ($IsWindows) {
        Assert-NotNullOrWhitespace $config.WingetId -ErrorText "$Tool has no WingetId — use Uninstall-$Tool directly"
        if ($config.WingetScope -ne 'user') {
            Assert-IsAdministrator -ErrorText "Uninstall-$Tool on Windows requires Administrator (winget machine-scope). Run as Administrator or uninstall $Tool manually."
        }
        Assert-Command winget
        $packageId = $config.WingetId -f $Version

        # Snapshot User PATH before uninstall so we can detect what the
        # uninstaller removes. Winget uninstallers often remove their registry
        # PATH entries but leave directories on disk — Test-Path alone can't
        # tell stale from legitimate.
        $beforeEntries = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]([System.Environment]::GetEnvironmentVariable('PATH', 'User') -split ';' |
                Where-Object { $_ -ne '' } |
                ForEach-Object { $_.TrimEnd('\', '/') }),
            [System.StringComparer]::OrdinalIgnoreCase
        )

        Invoke-CliCommand "winget uninstall --id $packageId --silent"

        # Find entries the uninstaller removed from the registry
        $afterEntries = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]([System.Environment]::GetEnvironmentVariable('PATH', 'User') -split ';' |
                Where-Object { $_ -ne '' } |
                ForEach-Object { $_.TrimEnd('\', '/') }),
            [System.StringComparer]::OrdinalIgnoreCase
        )
        $removed = [System.Collections.Generic.HashSet[string]]::new($beforeEntries, [System.StringComparer]::OrdinalIgnoreCase)
        $removed.ExceptWith($afterEntries)

        # Remove those entries from the session PATH too
        if ($removed.Count -gt 0) {
            $env:PATH = ($env:PATH -split ';' |
                Where-Object { $_ -eq '' -or -not $removed.Contains($_.TrimEnd('\', '/')) }) -join ';'
        }

        # Some uninstallers remove the directory but leave the PATH entry in
        # the registry (e.g. Terraform). Clean those by checking existence.
        $userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
        if ($userPath) {
            $cleaned = ($userPath -split ';' |
                Where-Object { $_ -eq '' -or (Test-Path $_) }) -join ';'
            if ($cleaned -ne $userPath) {
                [System.Environment]::SetEnvironmentVariable('PATH', $cleaned, 'User')
            }
        }
        $env:PATH = ($env:PATH -split ';' |
            Where-Object { $_ -eq '' -or (Test-Path $_) }) -join ';'
    }
    elseif ($IsMacOS) {
        Assert-NotNullOrWhitespace $config.BrewFormula -ErrorText "$Tool has no BrewFormula — use Uninstall-$Tool directly"
        Assert-Command brew
        $formula = $config.BrewFormula -f $Version
        Invoke-CliCommand "brew uninstall $formula"
    }
    elseif ($IsLinux) {
        Assert-NotNullOrWhitespace $config.AptPackage -ErrorText "$Tool has no AptPackage — use Uninstall-$Tool directly"
        Assert-IsAdministrator -ErrorText "Uninstall-$Tool on Linux requires root (apt-get). Run as root or uninstall $Tool manually."
        Assert-Command apt-get
        $package = $config.AptPackage -f $Version
        Invoke-CliCommand "sudo apt-get remove -y $package"
    }
    else {
        throw "Unsupported platform for tool uninstallation"
    }

    Write-Information "$Tool $Version uninstalled"
}
