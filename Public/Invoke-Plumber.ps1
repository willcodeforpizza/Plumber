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

        .EXAMPLE
        Invoke-Plumber

        Runs the default Validate task and prints a task/error summary.

        .EXAMPLE
        Invoke-Plumber -Task Pester

        Runs the Pester parent task.

        .EXAMPLE
        Invoke-Plumber -Task PSScriptAnalyzer, PesterUnit

        Runs specific validation tasks.
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
        $Task = 'Validate'
    )
    process {
        $moduleRoot = if ($script:moduleRoot) {
            $script:moduleRoot
        } else {
            Split-Path $PSScriptRoot -Parent
        }

        $buildFile = Join-Path $moduleRoot 'Plumber.build.ps1'
        if (-not (Get-Command Invoke-PlumberBuild -ErrorAction SilentlyContinue)) {
            . (Join-Path $moduleRoot 'Private/Invoke-PlumberBuild.ps1')
        }

        Write-Verbose "Build file: $buildFile"
        $buildResult = Invoke-PlumberBuild -Task $Task -BuildFile $buildFile
        $hasError = $buildResult.tasks | Where-Object {$_.Error}
        if($hasError) {
            Write-Error 'Build failed!'
        }

        Write-Output "$(
            $buildResult.tasks |
            Select-Object Name, Error |
            Format-Table |
                Out-String
        )"
    }
}
