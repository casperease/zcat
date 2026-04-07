<#
.SYNOPSIS
    Uninstalls Java via the platform package manager.
.DESCRIPTION
    Removes JAVA_HOME from the environment after uninstalling.
    On Unix, removes the marker block from $PROFILE.
.PARAMETER Version
    Java version to uninstall. Defaults to the locked version in Get-ToolConfig.
.EXAMPLE
    Uninstall-Java
#>
function Uninstall-Java {
    [CmdletBinding()]
    param(
        [string] $Version
    )

    Uninstall-Tool -Tool 'Java' -Version $Version

    # Clean up JAVA_HOME
    $env:JAVA_HOME = $null

    if ($IsWindows) {
        [Environment]::SetEnvironmentVariable('JAVA_HOME', $null, 'User')
    }
    else {
        $marker = '>>> zcat Install-Java >>>'
        $endMarker = '<<< zcat Install-Java <<<'
        $profilePath = $PROFILE.CurrentUserCurrentHost

        if (Test-Path $profilePath) {
            $content = Get-Content $profilePath -Raw
            if ($content -match [regex]::Escape($marker)) {
                $pattern = "(?ms)\r?\n# $([regex]::Escape($marker)).*?# $([regex]::Escape($endMarker))\r?\n?"
                $cleaned = $content -replace $pattern, ''
                Set-Content -Path $profilePath -Value $cleaned -NoNewline
            }
        }
    }
}
