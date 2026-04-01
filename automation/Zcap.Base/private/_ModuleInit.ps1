# Module initialization — runs at import time (before function definitions).
# Loads the C# CliRunner type and detects stale types from prior sessions.
# See ADR: conventional-folder-structure for the _ModuleInit.ps1 convention.

$csPath = Join-Path $PSScriptRoot '..' 'assets' 'CliRunner.cs'

if (([System.Management.Automation.PSTypeName]'Zcap.CliRunner').Type) {
    # Type survives module reimport (.NET AppDomain persists).
    # Check if the source file changed — if so, the loaded type is stale.
    if (Test-Path $csPath) {
        $currentHash = (Get-FileHash $csPath -Algorithm SHA256).Hash
        if ($global:__ZcapCliRunnerHash -and $global:__ZcapCliRunnerHash -ne $currentHash) {
            throw "CliRunner.cs has changed since the Zcap.CliRunner type was loaded. Restart PowerShell to pick up changes."
        }
        $global:__ZcapCliRunnerHash = $currentHash
    }
}
else {
    # First load — compile C# and cache hash.
    # Cannot use Assert-PathExist here — _ModuleInit runs before functions are defined.
    if (-not (Test-Path $csPath)) {
        throw "CliRunner.cs not found at '$csPath'. The Zcap.Base module requires this asset."
    }
    Add-Type -Path $csPath
    $global:__ZcapCliRunnerHash = (Get-FileHash $csPath -Algorithm SHA256).Hash
}
