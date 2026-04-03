<#
.SYNOPSIS
    Installs Microsoft OpenJDK via the platform package manager.
.DESCRIPTION
    After installation, sets JAVA_HOME for the current session and
    persists it for future sessions (User registry on Windows, $PROFILE
    on Unix). Modeled on Install-Dotnet / DOTNET_ROOT.
    Idempotent — skips if already installed at the correct version.
.PARAMETER Version
    Java version to install. Defaults to the locked version in Get-ToolConfig.
.PARAMETER Force
    Replace an existing installation at the wrong version.
.EXAMPLE
    Install-Java
.EXAMPLE
    Install-Java -Version '21'
#>
function Install-Java {
    [CmdletBinding()]
    param(
        [string] $Version,
        [switch] $Force
    )

    $config = Get-ToolConfig -Tool 'Java'
    if (-not $Version) { $Version = $config.Version }

    # Skip entirely if already at correct version — no install, no profile patching
    if (Test-Command $config.Command) {
        $installed = Get-ToolVersion -Config $config
        if ($installed -and $installed.StartsWith($Version)) {
            Write-Message "Java $Version is already installed"
            return
        }
    }

    Install-Tool -Tool 'Java' -Version $Version -Force:$Force

    # Resolve JAVA_HOME from the installed binary location
    $cmd = Get-Command $config.Command -ErrorAction SilentlyContinue
    if (-not $cmd) { return }

    $javaHome = if ($IsWindows) {
        # winget installs to LOCALAPPDATA\Programs\Microsoft\jdk-<version>.*\
        $jdkDir = Get-ChildItem "$env:LOCALAPPDATA\Programs\Microsoft" -Directory -Filter "jdk-$Version*" -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            Select-Object -First 1
        if ($jdkDir) { $jdkDir.FullName } else { Split-Path (Split-Path $cmd.Source) }
    }
    elseif ($IsMacOS) {
        $brewResult = Invoke-CliCommand "brew --prefix openjdk@$Version" -PassThru -NoAssert -Silent
        if ($brewResult.Output) { Join-Path $brewResult.Output 'libexec' 'openjdk.jdk' 'Contents' 'Home' }
        else { Split-Path (Split-Path $cmd.Source) }
    }
    else {
        # Linux: /usr/lib/jvm/java-<version>-openjdk-<arch>
        $jvmDir = Get-ChildItem '/usr/lib/jvm' -Directory -Filter "java-$Version-openjdk-*" -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($jvmDir) { $jvmDir.FullName } else { Split-Path (Split-Path $cmd.Source) }
    }

    if (-not $javaHome -or -not (Test-Path $javaHome)) {
        Write-Verbose "Could not resolve JAVA_HOME — skipping environment setup"
        return
    }

    # Set for current session
    $env:JAVA_HOME = $javaHome

    # Persist for future sessions
    if ($IsWindows) {
        [Environment]::SetEnvironmentVariable('JAVA_HOME', $javaHome, 'User')
    }
    else {
        $marker = '>>> zcap Install-Java >>>'
        $profilePath = $PROFILE.CurrentUserCurrentHost
        $profileDir = Split-Path $profilePath
        if (-not (Test-Path $profileDir)) {
            New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
        }
        $profileExists = Test-Path $profilePath
        $alreadyPatched = $profileExists -and (Get-Content $profilePath -Raw) -match [regex]::Escape($marker)

        if (-not $alreadyPatched) {
            $block = @"

# $marker
`$env:JAVA_HOME = "$javaHome"
# <<< zcap Install-Java <<<
"@
            Add-Content -Path $profilePath -Value $block
        }
    }

    Write-Verbose "JAVA_HOME set to '$javaHome'"
}
