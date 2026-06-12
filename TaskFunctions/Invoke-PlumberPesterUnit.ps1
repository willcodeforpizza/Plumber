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
        ModuleManifest   = $script:moduleManifest.FullName
        CodeCoveragePath = $script:moduleFolders
        StreamOutput     = $script:PlumberConfig.Tasks.PesterUnit.StreamOutput
    }
    $result = Invoke-PlumberPester @pesterSplat
    $script:pesterResult = $result

    if ($result.Result -eq 'Failed') {
        Write-Error (Get-PlumberPesterFailureMessage -Result $result)
    }
}
