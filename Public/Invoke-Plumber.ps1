function Invoke-Plumber {
    <#
        .SYNOPSIS
        Runs a Plumber Invoke-Build task pipeline.

        .DESCRIPTION
        Runs Plumber's Invoke-Build pipeline by loading the module build file and
        returning a summary of task errors. By default, Invoke-Plumber runs the
        Validate task.

        .PARAMETER Task
        The task, or parent task, to run. Defaults to Validate.

        .PARAMETER OutputMode
        Controls Plumber output. Summary is quiet and concise, Table prints all
        task results, Json emits structured output, and Raw preserves
        Invoke-Build output.

        .EXAMPLE
        Invoke-Plumber

        Runs the default Validate task and prints a concise summary.

        .EXAMPLE
        Invoke-Plumber -Task PesterUnit -OutputMode Table

        Runs PesterUnit and prints all task results as a table.

        .EXAMPLE
        Invoke-Plumber -Task PSScriptAnalyzer, PesterUnit -OutputMode Json

        Runs specific validation tasks and emits JSON output.
    #>
    [CmdletBinding()]
    param (
    # The name of the task, or parent task to run against the module
    [ValidateSet(
        'Backticks',
        'Changelog',
        'CodeCoverage',
        'CodeQuality',
        'Content',
        'Help',
        'JSON',
        'JSONSchema',
        'License',
        'LineLength',
        'Manifest',
        'ModuleConventions',
        'ModuleVersion',
        'Naming',
        'PesterIntegration',
        'PesterUnit',
        'PSScriptAnalyzer',
        'PublicFunctions',
        'ReleaseHygiene',
        'SetVariables',
        'Structure',
        'ToDo',
        'Validate',
        'YAML'
        )]
        [string[]]
        $Task = 'Validate',

        [ValidateSet('Json', 'Raw', 'Summary', 'Table')]
        [string]
        $OutputMode = 'Summary'
    )
    process {
        $moduleRoot = if ($script:moduleRoot) {
            $script:moduleRoot
        } else {
            Split-Path $PSScriptRoot -Parent
        }

        $buildFile = Join-Path $moduleRoot 'Plumber.build.ps1'
        # Self-validation can reload Plumber while Invoke-Plumber is running.
        $runtimeFunctions = 'Invoke-PlumberBuild', 'ConvertTo-PlumberResult', 'Write-PlumberResult'
        foreach ($runtimeFunction in $runtimeFunctions) {
            if (-not (Get-Command $runtimeFunction -ErrorAction SilentlyContinue)) {
                . (Join-Path $moduleRoot "Private/$runtimeFunction.ps1")
            }
        }

        Write-Verbose "Build file: $buildFile"
        $buildSplat = @{
            Task      = $Task
            BuildFile = $buildFile
            RawOutput = $OutputMode -eq 'Raw'
        }
        $buildResult = Invoke-PlumberBuild @buildSplat
        foreach ($runtimeFunction in $runtimeFunctions) {
            if (-not (Get-Command $runtimeFunction -ErrorAction SilentlyContinue)) {
                . (Join-Path $moduleRoot "Private/$runtimeFunction.ps1")
            }
        }

        $plumberResult = ConvertTo-PlumberResult -BuildResult $buildResult
        Write-PlumberResult -Result $plumberResult -OutputMode $OutputMode

        if (-not $plumberResult.Success) {
            throw 'Build failed!'
        }
    }
}
