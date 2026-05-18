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

    $script:pesterResult | ForEach-Object {
        $file = $_.Containers[0].Name
        $percent = $_.CodeCoverage.CoveragePercent
        if ($percent -lt $script:PlumberConfig.Tasks.CodeCoverage.Minimum) {
            Write-Error "$percent% coverage for $file"
        }
    }
}
