<#
.SYNOPSIS
    Scans a directory recursively for YAML files and classifies each as Pipeline, Template, or Unknown.
.DESCRIPTION
    Finds all .yml and .yaml files under the specified path, parses each with
    ConvertFrom-Yaml, and uses top-level key heuristics to classify the file
    as an Azure DevOps pipeline, a template (with subtype), or unknown.

    Files that fail YAML parsing are included in the output with ParseError set
    and Classification set to Unknown.
.PARAMETER Path
    Root directory to scan. Defaults to the repository root via Get-RepositoryRoot.
.PARAMETER Exclude
    Directory names to skip during scanning. Matched as exact names anywhere in the path.
    Defaults to @('.git', 'node_modules', '.terraform').
.EXAMPLE
    Get-AdoYamlFiles -Path 'C:\repos\big-mono'
.EXAMPLE
    Get-AdoYamlFiles -Path 'C:\repos\big-mono' -Exclude @('.git', 'node_modules', 'vendor')
#>
function Get-AdoYamlFiles {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [string] $Path,

        [string[]] $Exclude = @('.git', 'node_modules', '.terraform')
    )

    $scanRoot = if ($Path) { $Path } else { Get-RepositoryRoot }
    Assert-NotNullOrWhitespace $scanRoot -ErrorText 'Path is required. Set -Path or ensure $env:RepositoryRoot is set.'
    Assert-PathExist $scanRoot

    $scanRoot = (Resolve-Path $scanRoot).Path

    Write-Message "Scanning for YAML files in: $scanRoot"

    $allFiles = Get-ChildItem -Path $scanRoot -Recurse -Include '*.yml', '*.yaml' -File

    $filteredFiles = foreach ($file in $allFiles) {
        $excluded = $false
        foreach ($ex in $Exclude) {
            $escapedEx = [regex]::Escape($ex)
            if ($file.FullName -match "[\\/]$escapedEx[\\/]") {
                $excluded = $true
                break
            }
        }
        if (-not $excluded) { $file }
    }

    $fileCount = ($filteredFiles | Measure-Object).Count
    Write-Message "Found $fileCount YAML files"

    foreach ($file in $filteredFiles) {
        $relativePath = $file.FullName.Substring($scanRoot.Length).TrimStart([IO.Path]::DirectorySeparatorChar, '/') -replace '\\', '/'
        $directory = Split-Path $relativePath -Parent
        if ($directory) { $directory = $directory -replace '\\', '/' }

        $yaml = $null
        $parseError = $null
        $topLevelKeys = @()

        try {
            $content = Get-Content $file.FullName -Raw

            if ([string]::IsNullOrWhiteSpace($content)) {
                $parseError = 'File is empty'
            }
            else {
                $yaml = ConvertFrom-Yaml -Yaml $content -Ordered
            }
        }
        catch {
            $parseError = $_.Exception.Message
        }

        if ($yaml -is [System.Collections.IDictionary]) {
            $topLevelKeys = @($yaml.Keys)
        }

        $result = Resolve-AdoYamlClassification -Yaml $yaml

        [PSCustomObject]@{
            Path           = $file.FullName
            RelativePath   = $relativePath
            Directory      = $directory
            Classification = $result.Classification
            TemplateType   = $result.TemplateType
            TopLevelKeys   = $topLevelKeys
            ParseError     = $parseError
        }
    }
}
