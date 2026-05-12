function Add-PlumberTaskGroup {
    <#
        .SYNOPSIS
        Adds a built-in Plumber task group and its enabled children.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable]
        $TaskGroup,

        [Parameter(Mandatory)]
        [string]
        $TaskRoot
    )

    if (
        -not (Test-PlumberTaskEnabled -Name $TaskGroup.Parent -ExcludeTasks $script:PlumberConfig.ExcludeTasks)
    ) {
        return
    }

    foreach ($childTask in $TaskGroup.Children) {
        if (
            $childTask -eq 'CodeCoverage' -and
            $script:PlumberTaskJobs.CodeQuality -notcontains '?PesterUnit'
        ) {
            continue
        }

        $childSplat = @{
            Name     = $childTask
            Path     = "$($TaskGroup.Parent)/$childTask.ps1"
            TaskRoot = $TaskRoot
            Parent   = $TaskGroup.Parent
        }
        Add-PlumberTask @childSplat
    }

    if (-not $script:PlumberTaskJobs[$TaskGroup.Parent]) {
        return
    }

    $parentSplat = @{
        Name     = $TaskGroup.Parent
        Path     = "$($TaskGroup.Parent)/$($TaskGroup.Parent).ps1"
        TaskRoot = $TaskRoot
        Parent   = 'Validate'
    }
    Add-PlumberTask @parentSplat
}
