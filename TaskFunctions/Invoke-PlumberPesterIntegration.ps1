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

    if ($result.Result -eq 'Failed') {
        Write-Error (Get-PlumberPesterFailureMessage -Result $result)
    }
}
