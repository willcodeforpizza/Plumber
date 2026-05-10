<#
    .SYNOPSIS
    Validates code coverage is over the configured minimum for each file tested
#>
Add-BuildTask -Name CodeCoverage -Jobs ?PesterUnit, {
    if (-not $script:pesterResult) {
        Write-Build Yellow 'No Pester unit test results found'
        return
    }

    $script:pesterResult | ForEach-Object {
        $file = $_.Containers[0].Name
        $percent = $_.CodeCoverage.CoveragePercent
        if ($percent -lt $script:PlumberConfig.CoverageMinimum) {
            Write-Error "$percent% coverage for $file"
        }
    }
}
