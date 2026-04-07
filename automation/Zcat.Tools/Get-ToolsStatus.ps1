<#
.SYNOPSIS
    Reports the installation status of all registered tools.
.DESCRIPTION
    Reads tool definitions from config/tools.yml and checks each tool's
    presence, version, package manager, and install scope on the current
    machine. Returns status objects for programmatic use and writes a summary.
    Idempotent — safe to run at any time, read-only.
.EXAMPLE
    Get-ToolsStatus
.EXAMPLE
    Get-ToolsStatus | Where-Object Status -ne 'OK'
#>
function Get-ToolsStatus {
    [CmdletBinding()]
    param()

    $configPath = Join-Path $PSScriptRoot 'assets' 'config' 'tools.yml'
    Assert-PathExist $configPath
    $allTools = Get-Content $configPath -Raw | ConvertFrom-Yaml

    Write-Message 'Getting status of tools'

    # --- Batch slow operations up front ---

    # Single winget list call instead of one per tool (~3s saved per winget tool).
    $wingetCache = $null
    if ($IsWindows -and (Test-Command winget)) {
        $wingetResult = Invoke-CliCommand 'winget list --accept-source-agreements --disable-interactivity' -PassThru -NoAssert -Silent
        $wingetCache = $wingetResult.Full
    }

    # Parallel version probes — each spawns a subprocess, so run them concurrently.
    # Only probe tools that are on PATH (missing tools skip the version check).
    $versionJobs = @{}
    foreach ($toolName in $allTools.Keys) {
        $config = $allTools[$toolName]
        if (Test-Command $config.Command) {
            $cmd = $config.VersionCommand
            $versionJobs[$toolName] = Start-ThreadJob -ScriptBlock {
                $ErrorActionPreference = 'Continue'
                Invoke-Expression "$using:cmd 2>&1"
            }
        }
    }

    # Collect all version probe results (blocks until all complete).
    $versionResults = @{}
    foreach ($toolName in $versionJobs.Keys) {
        $config = $allTools[$toolName]
        $output = $versionJobs[$toolName] | Receive-Job -Wait -AutoRemoveJob
        $full = ($output | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { [string]$_ }
        }) -join [Environment]::NewLine
        if ($full -match $config.VersionPattern) {
            $versionResults[$toolName] = $Matches['ver']
        }
    }

    # --- Per-tool status (now fast — no subprocesses) ---

    $results = foreach ($toolName in $allTools.Keys) {
        $config = $allTools[$toolName]

        # Mirror Test-ExpectedPackageManager check order:
        # ScriptInstall → platform-specific → pip → unknown
        $expectedMgr = if ($config.ScriptInstall) { 'script' }
                       elseif ($IsWindows -and $config.WingetId) { 'winget' }
                       elseif ($IsMacOS -and $config.BrewFormula) { 'brew' }
                       elseif ($IsLinux -and $config.AptPackage) { 'apt' }
                       elseif ($config.PipPackage) { 'pip' }
                       else { 'unknown' }

        # Tool not on PATH — nothing more to check
        if (-not (Test-Command $config.Command)) {
            [PSCustomObject]@{
                Tool      = $toolName
                Locked    = "$($config.Version).x"
                Installed = $null
                Status    = 'Missing'
                Location  = $null
                Manager   = $null
                Scope     = $null
                Action    = "Run Install-$toolName"
            }
            continue
        }

        $location = (Get-Command $config.Command).Source
        $installed = $versionResults[$toolName]

        $versionOk = $installed -and $installed.StartsWith($config.Version)
        $managedByExpected = Test-ExpectedPackageManager -Config $config -WingetListCache $wingetCache
        $manager = if ($managedByExpected) { $expectedMgr } else { 'other' }
        $scope = Get-InstallScope -Config $config -Location $location

        $status = $null
        $action = $null

        if ($versionOk -and $managedByExpected) {
            # Right version, right manager — scope doesn't matter. If winget
            # installed Python machine-wide, it works and we control it.
            $status = 'OK'
            $action = 'None'
        }
        elseif ($versionOk) {
            # Right version but installed outside our manager — usable as-is
            $status = 'Usable'
            $hasRemove = [bool](Get-Command "Remove-$toolName" -ErrorAction SilentlyContinue)
            $action = if ($hasRemove) {
                "Works, but not managed by $expectedMgr. To migrate: Remove-$toolName -Force (destructive — deletes '$location'), then Install-$toolName"
            } else {
                "Works, but not managed by $expectedMgr. Recommend: uninstall from '$location', then Install-$toolName"
            }
        }
        elseif ($managedByExpected) {
            # Wrong version but our manager controls it — easy fix
            $status = 'WrongVersion'
            $action = "Run Install-$toolName -Force"
        }
        else {
            # Wrong version AND installed outside our manager. Installing via
            # $expectedMgr would succeed but the existing binary on Machine PATH
            # would shadow it — the user would still run the old version.
            $status = 'WrongVersion'
            $hasRemove = [bool](Get-Command "Remove-$toolName" -ErrorAction SilentlyContinue)
            $action = if ($hasRemove) {
                "Shadows any new install. Run Remove-$toolName -Force (destructive — deletes '$location' and cleans PATH), then Install-$toolName"
            } else {
                "Installed outside $expectedMgr at '$location' — this binary shadows any new install. Uninstall it first, then Install-$toolName"
            }
        }

        [PSCustomObject]@{
            Tool      = $toolName
            Locked    = "$($config.Version).x"
            Installed = $installed
            Status    = $status
            Location  = $location
            Manager   = $manager
            Scope     = $scope
            Action    = $action
        }
    }

    # Chocolatey check — not a tools.yml tool, but a package manager
    # that should not be present (see ADR: use-proper-package-managers).
    # Only report if actually found — no noise when absent.
    if ($IsWindows -and (Test-Command choco)) {
        $results += [PSCustomObject]@{
            Tool      = 'Chocolatey'
            Locked    = $null
            Installed = 'present'
            Status    = 'Unwanted'
            Location  = (Get-Command choco).Source
            Manager   = $null
            Scope     = $null
            Action    = 'Run Uninstall-Chocolatey'
        }
    }

    # One-line summary via Write-Message
    $summary = ($results | ForEach-Object {
        $label = switch ($_.Status) {
            'OK'           { 'ok' }
            'Usable'       { 'usable' }
            'WrongVersion' { 'wrong version' }
            'Missing'      { 'missing' }
            'Unwanted'     { 'unwanted' }
        }
        "$($_.Tool) $label"
    }) -join ', '
    Write-Message $summary

    $results
}
