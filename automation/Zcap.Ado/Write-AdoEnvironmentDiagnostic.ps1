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

    $entries = foreach ($name in $whitelist) {
        $value = [System.Environment]::GetEnvironmentVariable($name)
        if ($null -ne $value) {
            @{ Name = $name; Value = $value }
        }
    }

    $sorted = $entries | Sort-Object { $_.Name }
    foreach ($entry in $sorted) {
        Write-Information "$($entry.Name.PadRight(40)) $($entry.Value)"
    }
}
