function Add-PlumberLocalTask {
    <#
        .SYNOPSIS
        Adds configured repository-local Plumber tasks.
    #>
    [CmdletBinding()]
    param ()

    if (
        -not $script:PlumberConfig.Tasks.Local -or
        -not (Test-PlumberTaskEnabled -Name Local -ExcludeTasks $script:PlumberConfig.Tasks.Exclude)
    ) {
        return
    }

    foreach ($localTaskPath in @($script:PlumberConfig.Tasks.Local)) {
        if (-not $localTaskPath) {
            continue
        }

        $localTaskName = [System.IO.Path]::GetFileNameWithoutExtension($localTaskPath)
        $taskEnabledSplat = @{
            Name         = $localTaskName
            ExcludeTasks = $script:PlumberConfig.Tasks.Exclude
        }
        $isLocalTaskEnabled = Test-PlumberTaskEnabled @taskEnabledSplat
        if (-not $isLocalTaskEnabled) {
            continue
        }

        $resolvedLocalTaskPath = if ([System.IO.Path]::IsPathRooted($localTaskPath)) {
            [System.IO.Path]::GetFullPath($localTaskPath)
        } elseif (Get-Variable -Name BuildRoot -ErrorAction SilentlyContinue) {
            [System.IO.Path]::GetFullPath((Join-Path $BuildRoot $localTaskPath))
        } else {
            [System.IO.Path]::GetFullPath($localTaskPath)
        }

        if (-not (Test-Path $resolvedLocalTaskPath -PathType Leaf)) {
            throw "Local task file not found: $localTaskPath"
        }

        . $resolvedLocalTaskPath
        $script:PlumberTaskJobs.Local += "?$localTaskName"
    }

    if ($script:PlumberTaskJobs.Local) {
        Add-BuildTask -Name Local -Jobs $script:PlumberTaskJobs.Local
        $script:PlumberTaskJobs.Validate += '?Local'
    }
}
