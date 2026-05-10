<#
    .SYNOPSIS
    Runs module convention validation
#>
Add-BuildTask -Name ModuleConventions -Jobs $script:PlumberTaskJobs.ModuleConventions
