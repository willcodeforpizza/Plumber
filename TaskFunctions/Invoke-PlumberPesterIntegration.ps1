function Invoke-PlumberPesterIntegration {
    <#
        .SYNOPSIS
        Runs the PesterIntegration task body.
    #>
    [CmdletBinding()]
    param ()

    $integrationTestPath = [System.IO.Path]::Combine($BuildRoot, 'Tests', 'Integration')
    if (-not (Test-Path $integrationTestPath)) {
        Write-Build Yellow 'No integration tests found'
        return
    }

    $pesterSplat = @{
        Path           = $integrationTestPath
        ModuleManifest = $script:moduleManifest.FullName
        StreamOutput   = $script:PlumberConfig.Tasks.PesterIntegration.StreamOutput
    }
    $result = Invoke-PlumberPester @pesterSplat

    $failures = $result | Where-Object { $_.Result -eq 'Failed' }
    if ($failures) { Write-Error "Pester failed with $($failures.count) error(s)" }
}
