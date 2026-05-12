function Add-PlumberLocalTask {
    <#
        .SYNOPSIS
        Adds configured repository-local Plumber tasks.
    #>
    [CmdletBinding()]
    param ()

    if (
        -not $script:PlumberConfig.LocalTasks -or
        -not (Test-PlumberTaskEnabled -Name Local -ExcludeTasks $script:PlumberConfig.ExcludeTasks)
    ) {
        return
    }

    foreach ($localTaskPath in @($script:PlumberConfig.LocalTasks)) {
        if (-not $localTaskPath) {
            continue
        }

        $localTaskName = [System.IO.Path]::GetFileNameWithoutExtension($localTaskPath)
        if (-not (Test-PlumberTaskEnabled -Name $localTaskName -ExcludeTasks $script:PlumberConfig.ExcludeTasks)) {
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
