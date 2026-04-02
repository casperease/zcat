<#
.SYNOPSIS
    Sets an Azure DevOps pipeline variable via the ##vso logging command.
.DESCRIPTION
    Wraps the ##vso[task.setvariable] command with name sanitization, output/secret
    flags, and automatic no-op when running outside a pipeline.

    Variable names are sanitized: periods, hyphens, and apostrophes are replaced
    with underscores to match ADO's downstream variable resolution behavior.

    When running locally (Test-IsRunningInPipeline returns false), the function
    logs the variable but does not emit the ##vso command.
.PARAMETER Name
    The variable name. Sanitized automatically (. - ' replaced with _).
.PARAMETER Value
    The variable value. Empty strings are allowed.
.PARAMETER IsOutput
    Mark as an output variable, accessible from downstream jobs via
    dependencies.JobName.outputs['StepName.VariableName'].
.PARAMETER IsSecret
    Mark as secret. ADO masks the value in all log output.
    The function also omits the value from its own Write-Message output.
.EXAMPLE
    Set-PipelineVariable -Name 'DeployTarget' -Value 'staging'
.EXAMPLE
    Set-PipelineVariable -Name 'dev.capi' -Value 'Deploy' -IsOutput
.EXAMPLE
    Set-PipelineVariable -Name 'ConnectionString' -Value $connStr -IsSecret
#>
function Set-PipelineVariable {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is required — ##vso commands must go to stdout via the host stream')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Name,

        [Parameter(Mandatory, Position = 1)]
        [AllowEmptyString()]
        [string] $Value,

        [switch] $IsOutput,
        [switch] $IsSecret
    )

    Assert-NotNullOrWhitespace $Name -ErrorText 'Pipeline variable name cannot be empty'

    $sanitizedName = $Name.Replace('.', '_').Replace('-', '_').Replace("'", '')

    if (-not (Test-IsRunningInPipeline)) {
        $displayValue = if ($IsSecret) { '***' } else { $Value }
        Write-Verbose "Skipping ##vso (not in pipeline): $sanitizedName = $displayValue"
        return
    }

    if ($IsSecret) {
        Write-Message "Setting pipeline variable: $sanitizedName = ***"
    }
    else {
        Write-Message "Setting pipeline variable: $sanitizedName = $Value"
    }

    $flags = "variable=$sanitizedName;"
    if ($IsOutput) {
        $flags += 'isOutput=true;'
    }
    $flags += "issecret=$($IsSecret.ToString().ToLower())"

    Write-Host "##vso[task.setvariable $flags]$Value"
}
