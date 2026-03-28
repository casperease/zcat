<#
.SYNOPSIS
    Asserts that the pipeline contains no objects.
.DESCRIPTION
    Throws on the first object received. Must be used as a pipeline consumer;
    passing -InputObject directly is an error.
.PARAMETER InputObject
    Pipeline input (do not pass directly).
.EXAMPLE
    Get-ChildItem *.log | Assert-PipelineEmpty
#>
function Assert-PipelineEmpty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object] $InputObject
    )

    begin {
        if ($PSBoundParameters.ContainsKey('InputObject')) {
            throw [System.ArgumentException]::new(
                'Assert-PipelineEmpty must take its input from the pipeline.',
                'InputObject'
            )
        }
    }

    process {
        throw "Assertion failed: pipeline was not empty — {0}, line {1}" -f $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber
    }
}
