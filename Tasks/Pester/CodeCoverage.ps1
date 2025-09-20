task CodeCoverage {
    if (-not $script:pesterResult) {
        Write-Build Yellow "No Pester unit test results found"
        return
    }

    $script:pesterResult | ForEach-Object {
        $file = $_.Containers[0].Name
        $percent = $_.CodeCoverage.CoveragePercent
        if ($percent -lt 75) {
            Write-Error "$percent% coverage for $file"
        }
    }
}
