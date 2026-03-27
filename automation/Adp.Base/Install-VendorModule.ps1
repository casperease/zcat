<#
.SYNOPSIS
    Saves a PowerShell module into the automation/.vendor directory.
.DESCRIPTION
    Downloads from the PowerShell Gallery and removes legacy .NET Framework
    folders that are not needed on PowerShell 7+.
    Must be run in a fresh session — loaded modules may lock files.
.PARAMETER Name
    The module name to install from the PowerShell Gallery.
.PARAMETER RequiredVersion
    Optional specific version to install. Installs latest if omitted.
.EXAMPLE
    Install-VendorModule 'Pester'
.EXAMPLE
    Install-VendorModule 'Pester' -RequiredVersion '5.5.0'
#>
function Install-VendorModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Name,
        [Parameter(Position = 1)]
        [string] $RequiredVersion
    )

    # Warn if the module is currently loaded — Save-Module may fail on locked files
    $loaded = Get-Module $Name -ErrorAction Ignore
    if ($loaded) {
        throw "Module '$Name' is currently loaded. Please run Install-VendorModule in a fresh PowerShell session."
    }

    $vendorRoot = Join-Path $env:RepositoryRoot 'automation/.vendor'

    if (-not (Test-Path $vendorRoot)) {
        New-Item -Path $vendorRoot -ItemType Directory -Force | Out-Null
    }

    $saveParams = @{
        Name  = $Name
        Path  = $vendorRoot
        Force = $true
    }

    if ($RequiredVersion) {
        $saveParams.RequiredVersion = $RequiredVersion
    }

    Save-Module @saveParams

    # Clean up legacy .NET Framework folders — we only target PS 7+ / .NET 6+
    $moduleDir = Join-Path $vendorRoot $Name
    $junkPatterns = @('net20', 'net35', 'net40', 'net45', 'net451', 'net452',
        'net46', 'net461', 'net462', 'net47', 'net471', 'net472', 'net48')
    Get-ChildItem -Path $moduleDir -Directory -Recurse |
        Where-Object { $_.Name -in $junkPatterns } |
        ForEach-Object {
            Remove-Item $_.FullName -Recurse -Force
            Write-Information "Removed legacy folder: $($_.FullName.Substring($vendorRoot.Length + 1))"
        }

    Write-Information "Installed vendor module: $Name$(if ($RequiredVersion) { " v$RequiredVersion" })"
}
