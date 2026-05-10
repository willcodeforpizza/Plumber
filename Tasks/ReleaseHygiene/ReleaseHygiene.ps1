<#
    .SYNOPSIS
    Runs release hygiene validation.

    .DESCRIPTION
    Runs validation tasks that check release-facing version and changelog state.

    .INCLUDES
    ModuleVersion
    ChangelogUpdated

    .RUN
    ```powershell
    Invoke-Plumber -Task ReleaseHygiene
    ```
#>
Add-BuildTask -Name ReleaseHygiene -Jobs $script:PlumberTaskJobs.ReleaseHygiene
