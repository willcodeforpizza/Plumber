function ConvertTo-PlumberTaskMarkdownIndex {
    <#
        .SYNOPSIS
        Converts Plumber task help metadata to a Markdown index.

        .DESCRIPTION
        Builds the generated Markdown index for documented Plumber tasks.

        .PARAMETER Help
        The parsed task help metadata.

        .EXAMPLE
        ConvertTo-PlumberTaskMarkdownIndex -Help $help

        Returns Markdown for the task index.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [pscustomobject[]]
        $Help
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('# Tasks')
    $lines.Add('')

    $groups = @($Help | Where-Object Includes | Sort-Object Name)
    if ($groups) {
        $lines.Add('## Groups')
        $lines.Add('')
        $lines.Add('| Group | Includes |')
        $lines.Add('| --- | --- |')

        foreach ($group in $groups) {
            $includes = @(
                foreach ($include in $group.Includes) {
                    '`' + $include + '`'
                }
            ) -join ', '
            $lines.Add("| [$($group.Name)]($($group.Name).md) | $includes |")
        }
        $lines.Add('')
    }

    $tasks = @($Help | Where-Object {$_.Group -and -not $_.Includes} | Sort-Object Group, Name)
    if ($tasks) {
        $lines.Add('## Tasks')
        $lines.Add('')
        $lines.Add('| Task | Group |')
        $lines.Add('| --- | --- |')

        foreach ($task in $tasks) {
            $group = '`' + $task.Group + '`'
            $lines.Add("| [$($task.Name)]($($task.Name).md) | $group |")
        }
        $lines.Add('')
    }

    $internalTasks = @(
        $Help | Where-Object {-not $_.Group -and -not $_.Includes} | Sort-Object Name
    )
    if ($internalTasks) {
        $lines.Add('## Internal')
        $lines.Add('')
        $lines.Add('| Task | Purpose |')
        $lines.Add('| --- | --- |')

        foreach ($task in $internalTasks) {
            $lines.Add("| [$($task.Name)]($($task.Name).md) | $($task.Synopsis) |")
        }
    }

    ($lines -join "`n").TrimEnd() + "`n"
}
