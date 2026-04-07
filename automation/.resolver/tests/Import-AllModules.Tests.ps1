BeforeAll {
    # Build an isolated sandbox with just importer + resolver
    $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) "resolver-test-$([guid]::NewGuid().ToString('N'))"
    $sandboxAuto = Join-Path $sandbox 'automation'
    New-Item -Path $sandboxAuto -ItemType Directory -Force | Out-Null

    Copy-Item -Path (Join-Path $env:RepositoryRoot 'importer.ps1') -Destination $sandbox
    $sandboxResolver = Join-Path $sandboxAuto '.resolver'
    New-Item -Path $sandboxResolver -ItemType Directory -Force | Out-Null
    Copy-Item -Path (Join-Path $env:RepositoryRoot 'automation/.resolver/Resolver.psm1') -Destination $sandboxResolver

    function Invoke-Sandbox {
        # Runs importer in a child pwsh process and returns loaded module info
        $script = @"
            . '$sandbox/importer.ps1'
            Get-Module | Where-Object { `$_.Path -like '$sandboxAuto*' -and `$_.Name -ne 'Resolver' } |
                ForEach-Object {
                    [PSCustomObject]@{
                        Name      = `$_.Name
                        Exported  = (`$_.ExportedFunctions.Keys | Sort-Object)
                    }
                } | ConvertTo-Json -Depth 3
"@
        $raw = pwsh -NoProfile -Command $script 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Importer failed: $raw"
        }
        if (-not $raw -or $raw -eq '') { return @() }
        $parsed = $raw | ConvertFrom-Json
        if ($parsed -isnot [System.Array]) { $parsed = @($parsed) }
        return $parsed
    }

    function Add-SandboxFunction {
        param([string]$Module, [string]$Function, [string]$Body, [switch]$Private)
        $dir = Join-Path $sandboxAuto $Module
        if ($Private) { $dir = Join-Path $dir 'private' }
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $dir "$Function.ps1") -Value "function $Function { $Body }"
    }

    function Remove-SandboxFunction {
        param([string]$Module, [string]$Function, [switch]$Private)
        $dir = Join-Path $sandboxAuto $Module
        if ($Private) { $dir = Join-Path $dir 'private' }
        Remove-Item -Path (Join-Path $dir "$Function.ps1") -Force
    }

    function Remove-SandboxModule {
        param([string]$Module)
        Remove-Item -Path (Join-Path $sandboxAuto $Module) -Recurse -Force
    }

    function Invoke-SandboxFunction {
        param([string]$Function, [string]$FunctionArgs = '')
        $script = @"
            . '$sandbox/importer.ps1'
            $Function $FunctionArgs
"@
        $raw = pwsh -NoProfile -Command $script 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Failed: $raw" }
        return $raw
    }
}

AfterAll {
    if (Test-Path $sandbox) {
        Remove-Item $sandbox -Recurse -Force
    }
}

Describe 'Resolver' {
    Context 'empty automation folder' {
        It 'imports without error and loads no modules' {
            $modules = Invoke-Sandbox
            $modules | Should -HaveCount 0
        }
    }

    Context 'add module' {
        BeforeAll {
            Add-SandboxFunction -Module 'Acme' -Function 'Get-Acme' -Body '"hello"'
        }

        It 'discovers and loads new module' {
            $modules = Invoke-Sandbox
            $modules | Should -HaveCount 1
            $modules[0].Name | Should -Be 'Acme'
            $modules[0].Exported | Should -Contain 'Get-Acme'
        }
    }

    Context 'add function to module' {
        BeforeAll {
            Add-SandboxFunction -Module 'Acme' -Function 'Get-AcmeVersion' -Body '"1.0"'
        }

        It 'exports the new function' {
            $modules = Invoke-Sandbox
            $acme = $modules | Where-Object { $_.Name -eq 'Acme' }
            $acme.Exported | Should -Contain 'Get-Acme'
            $acme.Exported | Should -Contain 'Get-AcmeVersion'
        }
    }

    Context 'change public function' {
        BeforeAll {
            Add-SandboxFunction -Module 'Acme' -Function 'Get-Acme' -Body '"changed"'
        }

        It 'picks up the new implementation' {
            $result = Invoke-SandboxFunction -Function 'Get-Acme'
            $result | Should -Be 'changed'
        }
    }

    Context 'add private function' {
        BeforeAll {
            Add-SandboxFunction -Module 'Acme' -Function 'Get-AcmeSecret' -Body '"secret"' -Private
        }

        It 'does not export private function' {
            $modules = Invoke-Sandbox
            $acme = $modules | Where-Object { $_.Name -eq 'Acme' }
            $acme.Exported | Should -Not -Contain 'Get-AcmeSecret'
        }

        It 'private function is callable from public function' {
            Add-SandboxFunction -Module 'Acme' -Function 'Get-AcmeProxy' -Body 'Get-AcmeSecret'
            $result = Invoke-SandboxFunction -Function 'Get-AcmeProxy'
            $result | Should -Be 'secret'
        }
    }

    Context 'change private function' {
        BeforeAll {
            Add-SandboxFunction -Module 'Acme' -Function 'Get-AcmeSecret' -Body '"secret-v2"' -Private
        }

        It 'picks up the new implementation via public proxy' {
            $result = Invoke-SandboxFunction -Function 'Get-AcmeProxy'
            $result | Should -Be 'secret-v2'
        }
    }

    Context 'delete private function' {
        BeforeAll {
            Remove-SandboxFunction -Module 'Acme' -Function 'Get-AcmeSecret' -Private
            # Update proxy so it does not call the deleted function
            Add-SandboxFunction -Module 'Acme' -Function 'Get-AcmeProxy' -Body '"no-secret"'
        }

        It 'module still loads without the deleted private' {
            $modules = Invoke-Sandbox
            $acme = $modules | Where-Object { $_.Name -eq 'Acme' }
            $acme.Exported | Should -Not -Contain 'Get-AcmeSecret'
        }
    }

    Context 'delete public function' {
        BeforeAll {
            Remove-SandboxFunction -Module 'Acme' -Function 'Get-AcmeVersion'
        }

        It 'no longer exports the deleted function' {
            $modules = Invoke-Sandbox
            $acme = $modules | Where-Object { $_.Name -eq 'Acme' }
            $acme.Exported | Should -Not -Contain 'Get-AcmeVersion'
            $acme.Exported | Should -Contain 'Get-Acme'
        }
    }

    Context 'delete module' {
        BeforeAll {
            Remove-SandboxModule -Module 'Acme'
        }

        It 'module is gone' {
            $modules = Invoke-Sandbox
            $modules | Where-Object { $_.Name -eq 'Acme' } | Should -BeNullOrEmpty
        }
    }

    Context 'multiple modules' {
        BeforeAll {
            Add-SandboxFunction -Module 'Alpha' -Function 'Get-Alpha' -Body '"a"'
            Add-SandboxFunction -Module 'Beta' -Function 'Get-Beta' -Body '"b"'
        }

        AfterAll {
            Remove-SandboxModule -Module 'Alpha'
            Remove-SandboxModule -Module 'Beta'
        }

        It 'loads both modules independently' {
            $modules = Invoke-Sandbox
            ($modules | Where-Object { $_.Name -eq 'Alpha' }).Exported | Should -Contain 'Get-Alpha'
            ($modules | Where-Object { $_.Name -eq 'Beta' }).Exported | Should -Contain 'Get-Beta'
        }
    }
}
