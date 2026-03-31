<#
.SYNOPSIS
    Installs Terraform via the platform package manager.
.DESCRIPTION
    Windows: winget. macOS: Homebrew (hashicorp/tap). Linux: HashiCorp
    apt repository (configured inline if not already present).
    Idempotent — skips if already installed at the correct version.
.PARAMETER Version
    Terraform version to install. Defaults to the locked version in Get-ToolConfig.
.PARAMETER Force
    Replace an existing installation at the wrong version.
.EXAMPLE
    Install-Terraform
.EXAMPLE
    Install-Terraform -Version '1.15'
#>
function Install-Terraform {
    [CmdletBinding()]
    param(
        [string] $Version,
        [switch] $Force
    )

    if ($IsLinux) {
        $config = Get-ToolConfig -Tool 'Terraform'
        if (-not $Version) { $Version = $config.Version }

        # Idempotent: skip if already installed at the correct version
        if (Test-Command $config.Command) {
            $installed = Get-ToolVersion -Config $config

            if ($installed -and $installed.StartsWith($Version)) {
                Write-Message "Terraform $Version is already installed"
                return
            }

            if ($installed -and -not $Force) {
                $location = (Get-Command $config.Command).Source
                throw "Terraform version mismatch: expected $Version.x, found $installed at '$location'. Run Install-Terraform -Force to replace, or uninstall manually."
            }
        }

        Assert-IsAdministrator -ErrorText 'Install-Terraform on Linux requires root (apt-get). Run as root or install Terraform manually.'
        Assert-Command apt-get

        # Add HashiCorp apt repository if not already configured
        $sourcePath = '/etc/apt/sources.list.d/hashicorp.list'
        if (-not (Test-Path $sourcePath)) {
            Write-Message 'Adding HashiCorp apt repository'
            Invoke-CliCommand 'sudo apt-get update -qq'
            Invoke-CliCommand 'sudo apt-get install -y gnupg software-properties-common'
            Invoke-CliCommand 'wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg'
            Invoke-CliCommand 'echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list'
        }

        Invoke-CliCommand 'sudo apt-get update -qq'
        Invoke-CliCommand 'sudo apt-get install -y terraform'
        Assert-Command terraform -ErrorText 'Terraform was installed but is not on PATH. You may need to restart your shell.'
        Write-Information "Terraform $Version installed successfully"
        return
    }

    # Windows / macOS: delegate to Install-Tool (winget / brew)
    Install-Tool -Tool 'Terraform' -Version $Version -Force:$Force
}
