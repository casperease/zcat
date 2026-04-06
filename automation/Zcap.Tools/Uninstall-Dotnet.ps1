<#
.SYNOPSIS
    Uninstalls the .NET SDK installed by Install-Dotnet.
.DESCRIPTION
    Removes the ~/.dotnet directory and cleans persistent environment
    variables (DOTNET_ROOT and PATH). Idempotent — skips if the
    directory does not exist.
.EXAMPLE
    Uninstall-Dotnet
#>
function Uninstall-Dotnet {
    [CmdletBinding()]
    param()

    $config = Get-ToolConfig -Tool 'Dotnet'

    $installDir = Get-ScriptInstallDir -Config $config

    # Idempotent: skip if directory does not exist
    if (-not (Test-Path $installDir)) {
        Write-Message "Dotnet is not installed at '$installDir' — nothing to do"
        return
    }

    Write-Message "Removing '$installDir'"
    Remove-Item $installDir -Recurse -Force

    # Clean up current session + persistent PATH
    $env:DOTNET_ROOT = $null
    Remove-PermanentPath $installDir -Label 'Install-Dotnet'

    # Clean persistent DOTNET_ROOT separately
    if ($IsWindows) {
        [Environment]::SetEnvironmentVariable('DOTNET_ROOT', $null, 'User')
    }
    else {
        $profilePath = $PROFILE.CurrentUserCurrentHost
        if (Test-Path $profilePath) {
            $content = Get-Content $profilePath -Raw
            $startMarker = '>>> zcap DOTNET_ROOT >>>'
            $endMarker = '<<< zcap DOTNET_ROOT <<<'
            $cleaned = $content -replace "(?s)\r?\n?# $([regex]::Escape($startMarker)).*?# $([regex]::Escape($endMarker))\r?\n?", ''
            if ($cleaned -ne $content) {
                Set-Content -Path $profilePath -Value $cleaned -NoNewline
            }
        }
    }

    Write-Message "Dotnet uninstalled from '$installDir'"
}
