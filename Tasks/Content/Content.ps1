<#
    .SYNOPSIS
    Runs content validation
#>
Add-BuildTask -Name Content -Jobs $script:PlumberTaskJobs.Content
