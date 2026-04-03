<#
.SYNOPSIS
    Sets an Azure DevOps pipeline variable via the ##vso logging command.
.DESCRIPTION
    Wraps the ##vso[task.setvariable] command with output/secret flags
    and automatic no-op when running outside a pipeline.

    By default, throws if the variable name contains characters that ADO
    silently replaces during downstream resolution (. - '). This prevents
    hard-to-debug mismatches between the name you set and the name you
    reference. Use -SanitizeName to opt into automatic replacement instead.

    When running locally (Test-IsRunningInPipeline returns false), the function
    logs the variable but does not emit the ##vso command.
.PARAMETER Name
    The variable name. Must not contain . - ' unless -SanitizeName is set.
.PARAMETER Value
    The variable value. Empty strings are allowed so callers can clear
    a variable or signal "no value" to downstream jobs.
.PARAMETER IsOutput
    Mark as an output variable, accessible from downstream jobs via
    dependencies.JobName.outputs['StepName.VariableName'].
.PARAMETER IsSecret
    Mark as secret. ADO masks the value in all log output.
    The function also omits the value from its own Write-Message output.
.PARAMETER SanitizeName
    Replace . - ' with underscores instead of throwing. Use when the caller
    intentionally passes names with these characters (e.g. environment.template
    patterns from dynamic key generation).
.EXAMPLE
    Set-AdoPipelineVariable -Name 'DeployTarget' -Value 'staging'
.EXAMPLE
    Set-AdoPipelineVariable -Name 'dev_capi' -Value 'Deploy' -IsOutput
.EXAMPLE
    Set-AdoPipelineVariable -Name 'dev.capi' -Value 'Deploy' -SanitizeName
.EXAMPLE
    Set-AdoPipelineVariable -Name 'ConnectionString' -Value $connStr -IsSecret
#>
function Set-AdoPipelineVariable {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is required — ##vso commands must go to stdout via the host stream')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Name,

        [Parameter(Mandatory, Position = 1)]
        [AllowEmptyString()]
        [string] $Value,

        [switch] $IsOutput,
        [switch] $IsSecret,
        [switch] $SanitizeName
    )

    Assert-NotNullOrWhitespace $Name -ErrorText 'Pipeline variable name cannot be empty'

    if ($Name -match "[.\-']") {
        if ($SanitizeName) {
            $Name = $Name.Replace('.', '_').Replace('-', '_').Replace("'", '')
        }
        else {
            throw "Pipeline variable name '$Name' contains characters (. - ') that ADO silently replaces with underscores. " +
                  "Use underscores in the name directly, or pass -SanitizeName to opt into automatic replacement."
        }
    }

    if (-not (Test-IsRunningInPipeline)) {
        $displayValue = if ($IsSecret) { '***' } else { $Value }
        Write-Verbose "Skipping ##vso (not in pipeline): $Name = $displayValue"
        return
    }

    if ($IsSecret) {
        Write-Message "Setting pipeline variable: $Name = ***"
    }
    else {
        Write-Message "Setting pipeline variable: $Name = $Value"
    }

    $flags = "variable=$Name;"
    if ($IsOutput) {
        $flags += 'isOutput=true;'
    }
    $flags += "issecret=$($IsSecret.ToString().ToLower())"

    Write-Host "##vso[task.setvariable $flags]$Value"
}
