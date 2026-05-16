<#
    .SYNOPSIS
    Runs the full Plumber validation pipeline.

    .DESCRIPTION
    Runs all loaded validation task groups.

    .INCLUDES
    CodeQuality
    ReleaseHygiene
    Content
    ModuleConventions

    .RUN
    ```powershell
    Invoke-Plumber -Task Validate
    ```
#>
$validateJobs = @($script:PlumberTaskJobs.Validate) + {
    $taskNames = [ordered]@{}
    foreach ($taskName in $script:PlumberTaskJobs.Keys) {
        $taskNames[$taskName] = $true
    }

    foreach ($jobList in $script:PlumberTaskJobs.Values) {
        foreach ($job in @($jobList)) {
            if ($job -isnot [string]) {
                continue
            }

            $taskName = $job.TrimStart('?')
            if ($taskName) {
                $taskNames[$taskName] = $true
            }
        }
    }

    $failedTasks = @(
        foreach ($taskName in $taskNames.Keys) {
            try {
                if (Get-BuildError -Task $taskName) {
                    $taskName
                }
            } catch {
                continue
            }
        }
    )

    if ($failedTasks) {
        throw "One or more Plumber validation tasks failed: $($failedTasks -join ', ')"
    }
}
Add-BuildTask -Name Validate -Jobs $validateJobs
