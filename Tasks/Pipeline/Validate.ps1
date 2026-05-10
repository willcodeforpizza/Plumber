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
Add-BuildTask -Name Validate -Jobs $script:PlumberTaskJobs.Validate
