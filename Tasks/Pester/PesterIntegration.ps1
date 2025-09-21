<#
    .SYNOPSIS
    Runs integration tests and validates they pass
#>
task PesterIntegration SetVariables, {
    if (-not (Test-Path "$BuildRoot\Tests\Integration")) {
        Write-Build Yellow "No integration tests found"
        return
    }

    $config = New-PesterConfiguration
    $config.Run.Path = "$BuildRoot\Tests\Integration"
    $config.Run.PassThru = $true
    $result = Invoke-Pester -Configuration $config
    
    $failures = $result | Where-Object {$_.Result -eq 'Failed'}
    if($failures) {Write-Error "Pester failed with $($failures.count) error(s)"}
}