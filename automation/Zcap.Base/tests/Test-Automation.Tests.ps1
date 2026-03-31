BeforeDiscovery {
    $automationRoot = Join-Path $env:RepositoryRoot 'automation'

    $allPs1 = @()
    $allTests = @()
    $allDirs = Get-ChildItem -Path $automationRoot -Directory

    # Module directories (non-dot-prefixed)
    foreach ($moduleDir in ($allDirs | Where-Object { $_.Name -notmatch '^\.' })) {
        $publicFiles = Get-ChildItem -Path $moduleDir.FullName -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notlike '*.Tests.ps1' }
        foreach ($f in $publicFiles) {
            $allPs1 += @{ Module = $moduleDir.Name; File = $f }
        }

        $privatePath = Join-Path $moduleDir.FullName 'private'
        if (Test-Path $privatePath) {
            $privateFiles = Get-ChildItem -Path $privatePath -Filter '*.ps1' -File -ErrorAction SilentlyContinue
            foreach ($f in $privateFiles) {
                $allPs1 += @{ Module = $moduleDir.Name; File = $f; Private = $true }
            }
        }
    }

    # Collect test files from all directories (modules + infrastructure like .resolver)
    foreach ($dir in $allDirs | Where-Object { $_.Name -notin '.vendor', '.scriptanalyzer' }) {
        $testsPath = Join-Path $dir.FullName 'tests'
        if (Test-Path $testsPath) {
            $testFiles = Get-ChildItem -Path $testsPath -Filter '*.Tests.ps1' -File -ErrorAction SilentlyContinue
            foreach ($f in $testFiles) {
                $allTests += @{ Module = $dir.Name; File = $f }
            }
        }
    }
}

Describe '<Module>/<File>' -ForEach $allPs1 {
    BeforeAll {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $File.FullName, [ref]$tokens, [ref]$errors
        )
        $script:functions = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $false) | Where-Object { $_.Parent.Parent -eq $ast }
    }

    It 'file name is Verb-Noun format' {
        $File.BaseName | Should -Match '-'
    }

    It 'contains exactly one function' {
        $functions | Should -HaveCount 1
    }

    It "function name matches file name '<File>'" {
        $functions[0].Name | Should -Be $File.BaseName
    }
}

Describe 'Test file: <Module>/tests/<File>' -ForEach $allTests {
    It 'file name is Verb-Noun.Tests.ps1 format' {
        $File.BaseName -replace '\.Tests$' | Should -Match '-'
    }
}
