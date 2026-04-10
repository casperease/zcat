<#
.SYNOPSIS
    Classifies a parsed YAML document as Pipeline, Template, or Unknown.
.DESCRIPTION
    Inspects the top-level keys of a parsed YAML dictionary and applies
    heuristics to determine whether the file is an Azure DevOps pipeline,
    a template (stages/jobs/steps/variables), or unknown.

    Returns a PSCustomObject with Classification and TemplateType properties.
    TemplateType is set for templates (Stages, Jobs, Steps, Variables) and
    $null for non-templates.
.PARAMETER Yaml
    The parsed YAML object from ConvertFrom-Yaml. Accepts $null for files
    that failed to parse — returns Unknown classification.
.EXAMPLE
    $yaml = Get-Content 'ci.yml' -Raw | ConvertFrom-Yaml -Ordered
    $result = Resolve-AdoYamlClassification -Yaml $yaml
    $result.Classification  # 'Pipeline'
    $result.TemplateType    # $null
#>
function Resolve-AdoYamlClassification {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowNull()]
        [object] $Yaml
    )

    $unknown = [PSCustomObject]@{ Classification = 'Unknown'; TemplateType = $null }

    if ($null -eq $Yaml) {
        return $unknown
    }

    if ($Yaml -isnot [System.Collections.IDictionary]) {
        return $unknown
    }

    $keys = @($Yaml.Keys | ForEach-Object { $_.ToLower() })

    # Strong pipeline signals — any one is conclusive
    $strongPipelineKeys = @('trigger', 'pr', 'schedules', 'extends', 'lockbehavior')
    $hasStrongPipeline = $keys | Where-Object { $_ -in $strongPipelineKeys } | Select-Object -First 1

    if ($hasStrongPipeline) {
        return [PSCustomObject]@{ Classification = 'Pipeline'; TemplateType = $null }
    }

    # Template detection: parameters + body key
    $templateBodyMap = @{
        'stages'    = 'Stages'
        'jobs'      = 'Jobs'
        'steps'     = 'Steps'
        'variables' = 'Variables'
    }

    $hasParameters = 'parameters' -in $keys

    if ($hasParameters) {
        $bodyKey = $keys | Where-Object { $templateBodyMap.ContainsKey($_) } | Select-Object -First 1

        if ($bodyKey) {
            $templateType = $templateBodyMap[$bodyKey]
            return [PSCustomObject]@{ Classification = 'Template'; TemplateType = $templateType }
        }
    }

    # Moderate pipeline signals: pool/name/resources + stages/jobs without parameters
    $moderatePipelineKeys = @('pool', 'name', 'resources')
    $bodyKeys = @('stages', 'jobs')
    $hasModerate = $keys | Where-Object { $_ -in $moderatePipelineKeys } | Select-Object -First 1
    $hasBody = $keys | Where-Object { $_ -in $bodyKeys } | Select-Object -First 1

    if ($hasModerate -and $hasBody -and -not $hasParameters) {
        return [PSCustomObject]@{ Classification = 'Pipeline'; TemplateType = $null }
    }

    # Single-key files
    if ($keys.Count -eq 1) {
        $only = $keys[0]

        if ($only -eq 'steps') {
            return [PSCustomObject]@{ Classification = 'Template'; TemplateType = 'Steps' }
        }
        if ($only -eq 'variables') {
            return [PSCustomObject]@{ Classification = 'Template'; TemplateType = 'Variables' }
        }
    }

    $unknown
}
