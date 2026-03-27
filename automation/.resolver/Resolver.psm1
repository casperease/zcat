function New-DynamicManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [switch]$ExportPrivates
    )

    $moduleName = Split-Path $ModulePath -Leaf
    $manifestPath = Join-Path $ModulePath "$moduleName.psd1"

    # Collect public .ps1 files (root level) — file name = function name
    $publicFiles = Get-ChildItem -Path $ModulePath -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notlike '*.Tests.ps1' }

    # Collect private .ps1 files (private subfolder)
    $privatePath = Join-Path $ModulePath 'private'
    $privateFiles = @()
    if (Test-Path $privatePath) {
        $privateFiles = Get-ChildItem -Path $privatePath -Filter '*.ps1' -File -ErrorAction SilentlyContinue
    }

    # Private first so they're in scope before public functions load
    $allFiles = @($privateFiles) + @($publicFiles) | Where-Object { $_ }

    if ($allFiles.Count -eq 0) {
        Write-Warning "No .ps1 files found in '$ModulePath'"
        return $null
    }

    # .ps1 files in NestedModules run in the module's session state (shared scope)
    $nestedModules = $allFiles | ForEach-Object {
        $_.FullName.Substring($ModulePath.Length + 1)
    }

    # Export public functions (or all if ExportPrivates)
    $exportedFunctions = if ($ExportPrivates) {
        '*'
    } else {
        $publicFiles | ForEach-Object { $_.BaseName }
    }

    # Generate the psd1 manifest — manifest-only, no loader needed
    $manifestParams = @{
        Path              = $manifestPath
        RootModule        = ''
        ModuleVersion     = '0.1.0'
        PowerShellVersion = '7.6'
        NestedModules     = $nestedModules
        FunctionsToExport = $exportedFunctions
        CmdletsToExport   = @()
        VariablesToExport = @()
        AliasesToExport   = '*'
    }

    New-ModuleManifest @manifestParams
    return $manifestPath
}

<#
.SYNOPSIS
    Imports all module directories under a given root path.
.PARAMETER ModulesRoot
    Path to the directory containing module folders.
#>
function Import-AllModules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulesRoot,

        [switch]$ExportPrivates
    )

    $moduleDirs = Get-ChildItem -Path $ModulesRoot -Directory |
    Where-Object { $_.Name -notmatch '^\.' }

    # Remove previously loaded automation modules (handles deleted/renamed modules)
    Get-Module |
    Where-Object { $_.Path -like "$ModulesRoot*" -and $_.Name -ne 'Resolver' -and $_.Path -notlike '*/.vendor/*' -and $_.Path -notlike '*\.vendor\*' } |
    ForEach-Object {
        Write-Verbose "Removing stale module: $($_.Name)"
        Remove-Module $_.Name -Force -ErrorAction SilentlyContinue
    }

    # Clean up stale .psd1 manifests from previous runs
    Get-ChildItem -Path $ModulesRoot -Directory |
    Where-Object { $_.Name -notmatch '^\.' } |
    ForEach-Object {
        $stalePsd1 = Join-Path $_.FullName "$($_.Name).psd1"
        if (Test-Path $stalePsd1) {
            Remove-Item $stalePsd1 -Force
        }
    }

    foreach ($dir in $moduleDirs) {
        $manifestPath = New-DynamicManifest -ModulePath $dir.FullName -ExportPrivates:$ExportPrivates

        if ($manifestPath) {
            Write-Verbose "Importing module: $($dir.Name)"
            Import-Module $manifestPath -Scope Global -Force
        }
    }
}

<#
.SYNOPSIS
    Imports third-party modules from a vendor directory.
.PARAMETER VendorRoot
    Path to the vendor directory. Skips silently if the path does not exist.
#>
function Import-VendorModules {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VendorRoot,

        [string[]]$Lazy = @()
    )

    if (-not (Test-Path $VendorRoot)) {
        Write-Verbose "No vendor folder at '$VendorRoot' — skipping"
        return
    }

    $vendorDirs = Get-ChildItem -Path $VendorRoot -Directory

    foreach ($dir in $vendorDirs) {
        if ($dir.Name -in $Lazy) {
            Write-Verbose "Deferring vendor module $($dir.Name): marked as lazy"
            continue
        }

        $existing = Get-Module $dir.Name -ErrorAction SilentlyContinue

        # Already loaded from our vendor path — skip (re-importing can fail
        # if the module loaded .NET assemblies that can't be replaced in-process)
        if ($existing -and $existing.ModuleBase -like "$VendorRoot*") {
            $vendorVersion = (Split-Path $existing.ModuleBase -Leaf)
            $onDiskVersions = (Get-ChildItem -Path $dir.FullName -Directory).Name
            if ($onDiskVersions -and $vendorVersion -notin $onDiskVersions) {
                throw "Vendor module '$($dir.Name)' version changed on disk ($onDiskVersions) but $vendorVersion is loaded. Please restart your PowerShell session."
            }
            Write-Verbose "Skipping vendor module $($dir.Name): already loaded from vendor"
            continue
        }

        # Remove any system-installed version so the vendored one takes precedence
        if ($existing) {
            Write-Verbose "Removing existing module: $($existing.Name) $($existing.Version) from $($existing.ModuleBase)"
            Remove-Module $existing.Name -Force -ErrorAction SilentlyContinue
        }

        # Remove system paths for this module from PSModulePath so auto-loading
        # cannot resurrect the system version after we import the vendored one
        $sep = [System.IO.Path]::PathSeparator
        $env:PSModulePath = ($env:PSModulePath -split $sep |
            Where-Object {
                $candidate = Join-Path $_ $dir.Name
                -not (Test-Path $candidate -ErrorAction SilentlyContinue)
            }) -join $sep

        Write-Verbose "Importing vendor module: $($dir.Name)"
        try {
            Import-Module $dir.FullName -Scope Global -Force -ErrorAction Stop
        }
        catch {
            if ($_.Exception.InnerException -is [System.IO.FileLoadException] -or
                $_.Exception -is [System.IO.FileLoadException]) {
                # .NET assembly already loaded in-process (e.g., VS Code Extension Console)
                Write-Host "Skipping vendor module $($dir.Name): assembly already loaded in-process"
            }
            else {
                throw
            }
        }
    }

    # Prepend vendor root to PSModulePath so lazy (deferred) modules can autoload
    if ($Lazy.Count -gt 0) {
        $sep = [System.IO.Path]::PathSeparator
        if ($env:PSModulePath -split $sep -notcontains $VendorRoot) {
            $env:PSModulePath = $VendorRoot + $sep + $env:PSModulePath
        }
    }
}

Export-ModuleMember -Function 'Import-AllModules', 'Import-VendorModules'
