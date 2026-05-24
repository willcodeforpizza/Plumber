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

    $parentRunWhen = Get-PlumberTaskRunWhen -Name $TaskGroup.Parent
    $parentShouldRun = Test-PlumberTaskShouldRun -Name $TaskGroup.Parent -RunWhen $parentRunWhen
    if (-not $parentShouldRun) {
        $parentSplat = @{
            Name     = $TaskGroup.Parent
            Path     = "$($TaskGroup.Parent)/$($TaskGroup.Parent).ps1"
            TaskRoot = $TaskRoot
            Parent   = 'Validate'
        }
        Add-PlumberTask @parentSplat
        return
    }

    $pesterUnitRuns = $true
    foreach ($childTask in $TaskGroup.Children) {
        $childRunWhen = Get-PlumberTaskRunWhen -Name $childTask
        $childShouldRun = Test-PlumberTaskShouldRun -Name $childTask -RunWhen $childRunWhen

        if (
            $childTask -eq 'CodeCoverage' -and
            -not $pesterUnitRuns
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

        if ($childTask -eq 'PesterUnit') {
            $pesterUnitRuns = $childShouldRun
        }
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
