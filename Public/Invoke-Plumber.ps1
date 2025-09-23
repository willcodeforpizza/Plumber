function Invoke-Plumber {
    <#
        .SYNOPSIS
        Run an Invoke-Build pipeline on the current folder path

        .DESCRIPTION
        Run an Invoke-Build pipeline on the current folder path
        By default will run the "Validation" pipeline

        .PARAMETER Task
        The name of the task, or parent task to run against the module

        Generate list with
        gci .\Tasks\ -Recurse -file | select -expand BaseName | sort |
        foreach {write-host ('"' + $_ + '",')}

        .EXAMPLE
        Invoke-Plumber

        Build Validate .\MyModule\MyModule.build.ps1
        Task /Validate/SetVariables
        ...
        Build succeeded. 16 tasks, 0 errors, 0 warnings 00:00:00.1165774

        # By default, runs the Validation pipeline on the current module

        .EXAMPLE
        Invoke-Plumber -Task Pester

        Build Pester .\MyModule\MyModule.build.ps1
        Task /Pester/?PesterUnit
        No unit tests found
        Done /Pester/?PesterUnit 00:00:00.0014656
        Task /Pester/?CodeCoverage
        No Pester unit test results found
        Done /Pester/?CodeCoverage 00:00:00.0009108
        Task /Pester/?PesterIntegration
        No integration tests found
        Done /Pester/?PesterIntegration 00:00:00.0008585
        Done /Pester 00:00:00.0039792
        Build succeeded. 4 tasks, 0 errors, 0 warnings 00:00:00.0830835

        # Runs the Pester tests parent task
    #>
    [CmdletBinding()]
    param (
    # The name of the task, or parent task to run against the module
    [ValidateSet(
        'Changelog',
        'CodeCoverage',
        'JSON',
        'License',
        'Meta',
        'ModuleVersion',
        'Naming',
        'Pester',
        'PesterIntegration',
        'PesterUnit',
        'Psd1Data',
        'PSScriptAnalyzer',
        'PublicFunctions',
        'SetVariables',
        'Structure',
        'ToDo',
        'Validate',
        'DemoPipeline',
        'Task1',
        'TaskErr',
        'Task2',
        'Task3',
        'TaskA',
        'TaskB',
        'TaskLetters',
        'NestedPipeline'
        )]
        [string[]]
        $Task = 'Validate'
    )
    process {
        Invoke-Build -Task $Task -Result buildResult
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
        Pop-Location
    }
}
