<#
    .SYNOPSIS
    Main parent task to run the validation pipeline
#>
Add-BuildTask -Name Validate -Jobs $script:PlumberTaskJobs.Validate
