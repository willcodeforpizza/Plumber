function Test-PlumberTaskEnabled {
    <#
        .SYNOPSIS
        Tests whether a Plumber task is enabled.

        .DESCRIPTION
        Compares a task name with the configured ExcludeTasks list and returns true
        when the task should be loaded.

        .PARAMETER Name
        The task name to check.

        .PARAMETER ExcludeTasks
        Task names that should not be loaded.

        .EXAMPLE
        Test-PlumberTaskEnabled -Name JSON -ExcludeTasks YAML

        Returns true because JSON is not excluded.

        .EXAMPLE
        Test-PlumberTaskEnabled -Name YAML -ExcludeTasks YAML

        Returns false because YAML is excluded.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [string[]]
        $ExcludeTasks = @()
    )

    $ExcludeTasks -notcontains $Name
}
