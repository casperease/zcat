<#
.SYNOPSIS
    Reports the installation status of all registered devbox tools.
.DESCRIPTION
    Reads tool definitions from config/tools.yml and checks each tool's
    presence, version, and package manager on the current machine.
    Returns status objects for programmatic use and writes a summary.
    Idempotent — safe to run at any time, read-only.
.EXAMPLE
    Get-DevBoxStatus
.EXAMPLE
    Get-DevBoxStatus | Where-Object Status -ne 'OK'
#>
function Get-DevBoxStatus {
    [CmdletBinding()]
    param()

    $configPath = Join-Path $PSScriptRoot 'config' 'tools.yml'
    Assert-PathExist $configPath
    $allTools = Get-Content $configPath -Raw | ConvertFrom-Yaml

    $results = foreach ($toolName in $allTools.Keys) {
        $config = $allTools[$toolName]

        $expectedMgr = if ($config.PipPackage) { 'pip' }
                       elseif ($IsWindows) { 'winget' }
                       elseif ($IsMacOS) { 'brew' }
                       elseif ($IsLinux) { 'apt' }
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
                Action    = "Run Install-$toolName"
            }
            continue
        }

        $location = (Get-Command $config.Command).Source

        # Parse installed version
        $installed = $null
        # -NoAssert: non-zero exit means version unavailable — reported as status, not error
        $raw = Invoke-CliCommand $config.VersionCommand -PassThru -NoAssert -Silent
        if ($raw -match $config.VersionPattern) {
            $installed = $Matches['ver']
        }

        $versionOk = $installed -and $installed.StartsWith($config.Version)
        $managedByExpected = Test-ExpectedPackageManager -Config $config
        $manager = if ($managedByExpected) { $expectedMgr } else { 'other' }

        $status = $null
        $action = $null

        if ($versionOk -and $managedByExpected) {
            $status = 'OK'
        }
        elseif ($versionOk) {
            # Right version but installed outside our manager — usable as-is
            $status = 'Usable'
            $action = "Works, but not managed by $expectedMgr. Recommend: uninstall from '$location', then Install-$toolName"
        }
        elseif ($managedByExpected) {
            # Wrong version but our manager controls it — easy fix
            $status = 'WrongVersion'
            $action = "Run Install-$toolName -Force"
        }
        else {
            # Wrong version AND installed outside our manager
            $status = 'WrongVersion'
            $action = "Not managed by $expectedMgr. Uninstall from '$location', then Install-$toolName"
        }

        [PSCustomObject]@{
            Tool      = $toolName
            Locked    = "$($config.Version).x"
            Installed = $installed
            Status    = $status
            Location  = $location
            Manager   = $manager
            Action    = $action
        }
    }

    # Chocolatey check — not a tools.yml tool, but a package manager
    # that should not be present (see ADR: use-proper-package-managers).
    $chocoInstalled = $IsWindows -and (Test-Command choco)
    $results += [PSCustomObject]@{
        Tool      = 'Chocolatey'
        Locked    = $null
        Installed = if ($chocoInstalled) { 'present' } else { $null }
        Status    = if ($chocoInstalled) { 'Unwanted' } else { 'OK' }
        Location  = if ($chocoInstalled) { (Get-Command choco).Source } else { $null }
        Manager   = $null
        Action    = if ($chocoInstalled) { 'Run Uninstall-Chocolatey' } else { $null }
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
