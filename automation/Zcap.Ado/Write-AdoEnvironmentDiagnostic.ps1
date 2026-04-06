<#
.SYNOPSIS
    Displays whitelisted environment variables for pipeline diagnostics.
.DESCRIPTION
    Reads the whitelist from assets/config/pipeline-env.yml and displays
    only those environment variables. Variables that are not set are shown
    as empty. Designed for the top of every Invoke-AdoScript run so
    operators see build context, paths, and agent info at a glance.
.EXAMPLE
    Write-AdoEnvironmentDiagnostic
#>
function Write-AdoEnvironmentDiagnostic {
    [CmdletBinding()]
    param()

    $whitelist = Get-AdoPipelineEnvWhitelist

    $whitelist |
    ForEach-Object {
        $value = [System.Environment]::GetEnvironmentVariable($_)
        if ($null -ne $value) {
            [PSCustomObject]@{
                Name  = $_
                Value = $value
            }
        }
    } |
    Sort-Object Name |
    Format-Table -Property @{ Expression = 'Name'; Width = 40 }, Value
}
