function Add-PlumberLocalTask {
    <#
        .SYNOPSIS
        Adds configured repository-local Plumber tasks.
    #>
    [CmdletBinding()]
    param ()

    if (-not $script:PlumberConfig.Tasks.Local) {
        return
    }

    foreach ($localTaskPath in @($script:PlumberConfig.Tasks.Local)) {
        if (-not $localTaskPath) {
            continue
        }

        $localTaskName = [System.IO.Path]::GetFileNameWithoutExtension($localTaskPath)
        $enforceWhen = Get-PlumberTaskEnforceWhen -Name $localTaskName
        $isLocalTaskEnabled = Test-PlumberTaskEnabled -Name $localTaskName -EnforceWhen $enforceWhen

        if ($isLocalTaskEnabled) {
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
        } else {
            $skipMessage = Get-PlumberTaskSkipMessage -Name $localTaskName -EnforceWhen $enforceWhen
            Add-BuildTask -Name $localTaskName -Jobs ({
                Write-Host $skipMessage
            }.GetNewClosure())
        }

        $script:PlumberTaskJobs.Local += "?$localTaskName"
    }

    if ($script:PlumberTaskJobs.Local) {
        Add-BuildTask -Name Local -Jobs $script:PlumberTaskJobs.Local
        $script:PlumberTaskJobs.Validate += '?Local'
    }
}
