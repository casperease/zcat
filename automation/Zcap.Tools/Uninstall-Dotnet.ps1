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

    # Windows: C:\tools\dotnet — matches Install-Dotnet (avoids OneDrive $HOME).
    # Unix: ~/.dotnet — standard Microsoft convention.
    $installDir = if ($IsWindows -and $config.WindowsInstallRoot) {
        Join-Path $config.WindowsInstallRoot ($config.WindowsInstallDir ?? $config.UserInstallDir)
    } else {
        Join-Path $HOME $config.UserInstallDir
    }

    # Idempotent: skip if directory does not exist
    if (-not (Test-Path $installDir)) {
        Write-Message "Dotnet is not installed at '$installDir' — nothing to do"
        return
    }

    Write-Message "Removing '$installDir'"
    Remove-Item $installDir -Recurse -Force

    # Clean up current session
    $env:DOTNET_ROOT = $null
    $env:PATH = ($env:PATH -split [System.IO.Path]::PathSeparator |
        Where-Object { $_ -ne $installDir }) -join [System.IO.Path]::PathSeparator

    # Clean persistent environment
    if ($IsWindows) {
        [Environment]::SetEnvironmentVariable('DOTNET_ROOT', $null, 'User')
        $userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
        if ($userPath) {
            $cleaned = ($userPath -split ';' | Where-Object { $_ -ne $installDir }) -join ';'
            [Environment]::SetEnvironmentVariable('PATH', $cleaned, 'User')
        }
    }
    else {
        # Remove the marker block from $PROFILE
        $profilePath = $PROFILE.CurrentUserCurrentHost
        if (Test-Path $profilePath) {
            $content = Get-Content $profilePath -Raw
            $startMarker = '>>> zcap Install-Dotnet >>>'
            $endMarker = '<<< zcap Install-Dotnet <<<'
            $pattern = "(?m)\r?\n?# \Q$startMarker\E.*?# \Q$endMarker\E\r?\n?"
            # Use regex with singleline mode to match across lines
            $cleaned = $content -replace "(?s)\r?\n?# $([regex]::Escape($startMarker)).*?# $([regex]::Escape($endMarker))\r?\n?", ''
            Set-Content -Path $profilePath -Value $cleaned -NoNewline
        }
    }

    Write-Message "Dotnet uninstalled"
}
