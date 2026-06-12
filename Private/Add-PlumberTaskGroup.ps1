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

    # CodeCoverage measures PesterUnit's test run, so it cannot run when
    # PesterUnit does not. Resolve PesterUnit's policy up front rather than
    # relying on it appearing before CodeCoverage in the child ordering.
    $pesterUnitRuns = $true
    if ($TaskGroup.Children -contains 'CodeCoverage') {
        $pesterUnitRunWhen = Get-PlumberTaskRunWhen -Name 'PesterUnit'
        $pesterUnitRuns = Test-PlumberTaskShouldRun -Name 'PesterUnit' -RunWhen $pesterUnitRunWhen
    }

    foreach ($childTask in $TaskGroup.Children) {
        $childSplat = @{
            Name     = $childTask
            Path     = "$($TaskGroup.Parent)/$childTask.ps1"
            TaskRoot = $TaskRoot
            Parent   = $TaskGroup.Parent
        }
        if ($childTask -eq 'CodeCoverage' -and -not $pesterUnitRuns) {
            $childSplat.SkipReason = (
                'Skipping CodeCoverage: PesterUnit does not run, ' +
                'so there is no test run to measure.'
            )
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
