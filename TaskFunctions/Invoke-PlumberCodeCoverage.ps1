function Invoke-PlumberCodeCoverage {
    <#
        .SYNOPSIS
        Runs the CodeCoverage task body.
    #>
    [CmdletBinding()]
    param ()

    if (-not $script:pesterResult) {
        Write-Build Yellow 'No Pester unit test results found'
        return
    }

    $coverage = $script:pesterResult.CodeCoverage
    if (-not $coverage) {
        Write-Build Yellow 'No code coverage data found'
        return
    }

    $minimum = $script:PlumberConfig.Tasks.CodeCoverage.Minimum
    $percent = $coverage.CoveragePercent
    if ($percent -lt $minimum) {
        $rounded = [math]::Round($percent, 2)
        Write-Error "Overall code coverage $rounded% is below the configured minimum of $minimum%"
    }
}
