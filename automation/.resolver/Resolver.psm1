function New-DynamicManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [switch]$ExportPrivates
    )

    $moduleName = Split-Path $ModulePath -Leaf
    $manifestPath = Join-Path $ModulePath "$moduleName.psd1"
    $pathPrefixLength = $ModulePath.Length + 1

    # Collect public .ps1 files (root level) — .NET API avoids Get-ChildItem pipeline overhead
    $publicFiles = @(foreach ($f in [System.IO.Directory]::EnumerateFiles($ModulePath, '*.ps1')) {
        if (-not [System.IO.Path]::GetFileName($f).EndsWith('.Tests.ps1', [System.StringComparison]::OrdinalIgnoreCase)) {
            $f
        }
    })

    # Collect private .ps1 files (private subfolder)
    $privatePath = Join-Path $ModulePath 'private'
    $initFile = @()
    $privateFiles = @()
    if ([System.IO.Directory]::Exists($privatePath)) {
        foreach ($f in [System.IO.Directory]::GetFiles($privatePath, '*.ps1')) {
            if ([System.IO.Path]::GetFileName($f) -eq '_ModuleInit.ps1') {
                $initFile = @($f)
            }
            else {
                $privateFiles += $f
            }
        }
    }

    if ($publicFiles.Count -eq 0 -and $privateFiles.Count -eq 0 -and $initFile.Count -eq 0) {
        Write-Verbose "No .ps1 files found in '$ModulePath'"
        return $null
    }

    # Init first (module load-time code), then private functions, then public
    $allFiles = $initFile + $privateFiles + $publicFiles

    # .ps1 files in NestedModules run in the module's session state (shared scope)
    $nestedEntries = foreach ($f in $allFiles) { "'{0}'" -f $f.Substring($pathPrefixLength) }
    $nestedList = $nestedEntries -join ', '

    # Export public functions (or all if ExportPrivates)
    $exportList = if ($ExportPrivates) {
        "'*'"
    }
    else {
        $names = foreach ($f in $publicFiles) { "'{0}'" -f [System.IO.Path]::GetFileNameWithoutExtension($f) }
        $names -join ', '
    }

    # Write minimal .psd1 directly — avoids New-ModuleManifest cmdlet overhead
    [System.IO.File]::WriteAllText($manifestPath, "@{
    RootModule        = ''
    ModuleVersion     = '0.1.0'
    PowerShellVersion = '7.4'
    NestedModules     = @($nestedList)
    FunctionsToExport = @($exportList)
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @('*')
}")
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

    foreach ($dir in $moduleDirs) {
        $manifestPath = New-DynamicManifest -ModulePath $dir.FullName -ExportPrivates:$ExportPrivates

        if ($manifestPath) {
            Write-Verbose "Importing module: $($dir.Name)"
            Import-Module $manifestPath -Scope Global -Force
        }
        else {
            # Clean up stale .psd1 if module dir became empty
            $stalePsd1 = Join-Path $dir.FullName "$($dir.Name).psd1"
            if ([System.IO.File]::Exists($stalePsd1)) {
                [System.IO.File]::Delete($stalePsd1)
            }
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Resolver runs before Write-Message is available')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VendorRoot,

        [string[]]$Lazy = @()
    )

    if (-not [System.IO.Directory]::Exists($VendorRoot)) {
        Write-Verbose "No vendor folder at '$VendorRoot' — skipping"
        return
    }

    $sep = [System.IO.Path]::PathSeparator
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
        $env:PSModulePath = ($env:PSModulePath -split $sep |
            Where-Object {
                -not [System.IO.Directory]::Exists((Join-Path $_ $dir.Name))
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
        if ($env:PSModulePath -split $sep -notcontains $VendorRoot) {
            $env:PSModulePath = $VendorRoot + $sep + $env:PSModulePath
        }
    }
}

Export-ModuleMember -Function 'Import-AllModules', 'Import-VendorModules'
