<#
    .SYNOPSIS
    Runs unit tests and validates they pass
#>
task -Name PesterUnit -Jobs SetVariables, {
    if (-not (Test-Path "$BuildRoot\Tests\Unit")) {
        Write-Build Yellow 'No unit tests found'
        return
    }

    $config = New-PesterConfiguration
    $config.Run.Path = "$BuildRoot\Tests\Unit"
    $config.Run.PassThru = $true
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = $script:moduleFolders
    $result = Invoke-Pester -Configuration $config
    $script:pesterResult = $result

    $global:foo =   $script:pesterResult

    $failures = $result | Where-Object { $_.Result -eq 'Failed' }
    if ($failures) { Write-Error "Pester failed with $($failures.count) error(s)" }
}
