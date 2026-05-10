function Test-PlumberTaskEnabled {
    <#
        .SYNOPSIS
        Tests whether a Plumber task is enabled.

        .DESCRIPTION
        Compares a task name with the configured SkipTasks list and returns true
        when the task should be loaded.

        .PARAMETER Name
        The task name to check.

        .PARAMETER SkipTasks
        Task names that should not be loaded.

        .EXAMPLE
        Test-PlumberTaskEnabled -Name JSON -SkipTasks YAML

        Returns true because JSON is not skipped.

        .EXAMPLE
        Test-PlumberTaskEnabled -Name YAML -SkipTasks YAML

        Returns false because YAML is skipped.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [string[]]
        $SkipTasks = @()
    )

    $SkipTasks -notcontains $Name
}
