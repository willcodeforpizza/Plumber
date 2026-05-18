function Invoke-PlumberPesterUnit {
    <#
        .SYNOPSIS
        Runs the PesterUnit task body.
    #>
    [CmdletBinding()]
    param ()

    $unitTestPath = [System.IO.Path]::Combine($BuildRoot, 'Tests', 'Unit')
    if (-not (Test-Path $unitTestPath)) {
        Write-Build Yellow 'No unit tests found'
        return
    }

    $pesterSplat = @{
        Path             = $unitTestPath
        ModuleManifest   = Join-Path $BuildRoot "$script:moduleName.psd1"
        CodeCoveragePath = $script:moduleFolders
        StreamOutput     = $script:PlumberConfig.Tasks.PesterUnit.StreamOutput
    }
    $result = Invoke-PlumberPester @pesterSplat
    $script:pesterResult = $result

    $failures = $result | Where-Object { $_.Result -eq 'Failed' }
    if ($failures) { Write-Error "Pester failed with $($failures.count) error(s)" }
}
