function Invoke-Plumber {
    <#
        .SYNOPSIS
        Runs a Plumber Invoke-Build task pipeline.

        .DESCRIPTION
        Runs a Plumber Invoke-Build pipeline by resolving a build file from the
        current directory and returning a summary of task errors. By default,
        Invoke-Plumber runs the Validate task.

        .PARAMETER Task
        The task, or parent task, to run. Defaults to Validate.

        .PARAMETER BuildFile
        The build file to run. Relative paths are resolved from the current
        directory. When omitted, Invoke-Plumber looks for a build file matching
        the module manifest in the current directory.

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

        [string]
        $BuildFile,

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

        # Self-validation can reload Plumber while Invoke-Plumber is running.
        $runtimeFunctions = @(
            'Invoke-PlumberBuild',
            'ConvertTo-PlumberResult',
            'Write-PlumberResult',
            'Resolve-PlumberBuildFile'
        )
        foreach ($runtimeFunction in $runtimeFunctions) {
            if (-not (Get-Command $runtimeFunction -ErrorAction SilentlyContinue)) {
                . (Join-Path $moduleRoot "Private/$runtimeFunction.ps1")
            }
        }

        $resolvedBuildFile = Resolve-PlumberBuildFile -BuildFile $BuildFile

        Write-Verbose "Build file: $resolvedBuildFile"
        $buildSplat = @{
            Task      = $Task
            BuildFile = $resolvedBuildFile
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
