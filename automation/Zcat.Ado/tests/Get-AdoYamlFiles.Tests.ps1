Describe 'Resolve-AdoYamlClassification' {
    InModuleScope 'Zcat.Ado' {
        Context 'null and non-dictionary input' {
            It 'returns Unknown for $null' {
                $result = Resolve-AdoYamlClassification -Yaml $null
                $result.Classification | Should -Be 'Unknown'
                $result.TemplateType | Should -BeNullOrEmpty
            }

            It 'returns Unknown for a scalar' {
                $result = Resolve-AdoYamlClassification -Yaml 'just a string'
                $result.Classification | Should -Be 'Unknown'
            }

            It 'returns Unknown for an array' {
                $result = Resolve-AdoYamlClassification -Yaml @('item1', 'item2')
                $result.Classification | Should -Be 'Unknown'
            }
        }

        Context 'strong pipeline signals' {
            It 'classifies trigger + jobs as Pipeline' {
                $yaml = [ordered]@{ trigger = @('main'); jobs = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Pipeline'
                $result.TemplateType | Should -BeNullOrEmpty
            }

            It 'classifies pr as Pipeline' {
                $yaml = [ordered]@{ pr = @('main'); stages = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Pipeline'
            }

            It 'classifies schedules as Pipeline' {
                $yaml = [ordered]@{ schedules = @(); stages = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Pipeline'
            }

            It 'classifies extends as Pipeline' {
                $yaml = [ordered]@{ extends = @{ template = 'base.yml' } }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Pipeline'
            }

            It 'classifies lockBehavior as Pipeline' {
                $yaml = [ordered]@{ lockBehavior = 'sequential'; stages = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Pipeline'
            }
        }

        Context 'template detection' {
            It 'classifies parameters + steps as Steps template' {
                $yaml = [ordered]@{ parameters = @(); steps = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Template'
                $result.TemplateType | Should -Be 'Steps'
            }

            It 'classifies parameters + jobs as Jobs template' {
                $yaml = [ordered]@{ parameters = @(); jobs = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Template'
                $result.TemplateType | Should -Be 'Jobs'
            }

            It 'classifies parameters + stages as Stages template' {
                $yaml = [ordered]@{ parameters = @(); stages = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Template'
                $result.TemplateType | Should -Be 'Stages'
            }

            It 'classifies parameters + variables as Variables template' {
                $yaml = [ordered]@{ parameters = @(); variables = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Template'
                $result.TemplateType | Should -Be 'Variables'
            }
        }

        Context 'moderate pipeline signals' {
            It 'classifies pool + jobs without parameters as Pipeline' {
                $yaml = [ordered]@{ pool = @{ vmImage = 'ubuntu-latest' }; jobs = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Pipeline'
            }

            It 'classifies name + resources + stages without parameters as Pipeline' {
                $yaml = [ordered]@{ name = '$(Rev:r)'; resources = @{}; stages = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Pipeline'
            }
        }

        Context 'single-key files' {
            It 'classifies lone steps as Steps template' {
                $yaml = [ordered]@{ steps = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Template'
                $result.TemplateType | Should -Be 'Steps'
            }

            It 'classifies lone variables as Variables template' {
                $yaml = [ordered]@{ variables = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Template'
                $result.TemplateType | Should -Be 'Variables'
            }

            It 'classifies lone stages as Unknown' {
                $yaml = [ordered]@{ stages = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Unknown'
            }

            It 'classifies lone jobs as Unknown' {
                $yaml = [ordered]@{ jobs = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Unknown'
            }
        }

        Context 'fallback' {
            It 'classifies arbitrary keys as Unknown' {
                $yaml = [ordered]@{ foo = 'bar'; baz = 42 }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Unknown'
            }

            It 'classifies config-like YAML as Unknown' {
                $yaml = [ordered]@{ Organization = 'https://dev.azure.com/org'; Project = 'proj' }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Unknown'
            }
        }

        Context 'strong pipeline wins over template indicators' {
            It 'classifies trigger + parameters + steps as Pipeline' {
                $yaml = [ordered]@{ trigger = @('main'); parameters = @(); steps = @() }
                $result = Resolve-AdoYamlClassification -Yaml $yaml
                $result.Classification | Should -Be 'Pipeline'
            }
        }
    }
}

Describe 'Get-AdoYamlFiles' {
    Context 'scanning real repo YAML' {
        BeforeAll {
            $repoRoot = $env:RepositoryRoot
            $results = Get-AdoYamlFiles -Path $repoRoot
        }

        It 'returns results' {
            $results | Should -Not -BeNullOrEmpty
        }

        It 'returns objects with expected properties' {
            $first = $results | Select-Object -First 1
            $first.PSObject.Properties.Name | Should -Contain 'Path'
            $first.PSObject.Properties.Name | Should -Contain 'RelativePath'
            $first.PSObject.Properties.Name | Should -Contain 'Root'
            $first.PSObject.Properties.Name | Should -Contain 'RelativeDirectory'
            $first.PSObject.Properties.Name | Should -Contain 'Classification'
            $first.PSObject.Properties.Name | Should -Contain 'TemplateType'
            $first.PSObject.Properties.Name | Should -Contain 'TopLevelKeys'
            $first.PSObject.Properties.Name | Should -Contain 'ParseError'
        }

        It 'uses forward slashes in RelativePath' {
            $results | ForEach-Object {
                $_.RelativePath | Should -Not -Match '\\'
            }
        }

        It 'classifies pipeline files as Pipeline' {
            $pipeline = $results | Where-Object { $_.RelativePath -like '*/ci.yaml' } | Select-Object -First 1
            if ($pipeline) {
                $pipeline.Classification | Should -Be 'Pipeline'
            }
        }

        It 'classifies template files as Template' {
            $template = $results | Where-Object { $_.RelativePath -like '*/steps/*.yaml' } | Select-Object -First 1
            if ($template) {
                $template.Classification | Should -Be 'Template'
            }
        }

        It 'has no parse errors for valid YAML files' {
            $errors = $results | Where-Object { $_.ParseError }
            $errors | Should -BeNullOrEmpty
        }
    }

    Context 'exclude filtering' {
        BeforeAll {
            $repoRoot = $env:RepositoryRoot
        }

        It 'excludes .git directory by default' {
            $results = Get-AdoYamlFiles -Path $repoRoot
            $gitFiles = $results | Where-Object { $_.RelativePath -match '^\\.git/' -or $_.RelativePath -match '^\.git/' }
            $gitFiles | Should -BeNullOrEmpty
        }
    }
}
