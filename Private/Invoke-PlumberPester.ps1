function Invoke-PlumberPester {
    <#
        .SYNOPSIS
        Runs Pester in an isolated PowerShell job.

        .DESCRIPTION
        Starts a background job so Pester runs in a separate process from the
        caller. This prevents loaded modules, mocks, aliases and other session
        state from leaking into tests while still streaming test output back to
        the Invoke-Build task.

        .PARAMETER Path
        Pester test path.

        .PARAMETER ModuleManifest
        Module manifest to import in the isolated test process.

        .PARAMETER CodeCoveragePath
        Optional source paths for Pester code coverage.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseUsingScopeModifierInNewRunspaces',
        '',
        Justification = 'Start-Job parameters are passed through ArgumentList.'
    )]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $ModuleManifest,

        [string[]]
        $CodeCoveragePath
    )

    $resultPath = Join-Path ([System.IO.Path]::GetTempPath()) (
        'plumber-pester-result-{0}.clixml' -f [guid]::NewGuid().ToString('N')
    )

    $job = Start-Job -ScriptBlock {
        param (
            [string]
            $TestPath,

            [string]
            $ManifestPath,

            [string[]]
            $CoveragePath,

            [string]
            $PesterResultPath
        )

        Import-Module $ManifestPath -Force

        $configuration = New-PesterConfiguration
        $configuration.Run.Path = $TestPath
        $configuration.Run.PassThru = $true

        if ($CoveragePath) {
            $configuration.CodeCoverage.Enabled = $true
            $configuration.CodeCoverage.Path = $CoveragePath
        }

        $result = Invoke-Pester -Configuration $configuration
        $result | Export-Clixml -Path $PesterResultPath
    } -ArgumentList $Path, $ModuleManifest, $CodeCoveragePath, $resultPath

    try {
        Receive-Job -Job $job -Wait

        if ($job.State -ne 'Completed') {
            throw "Pester job ended with state '$($job.State)'."
        }

        if (-not (Test-Path $resultPath -PathType Leaf)) {
            throw 'Pester job did not write a result file.'
        }

        Import-Clixml -Path $resultPath
    } finally {
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $resultPath -Force -ErrorAction SilentlyContinue
    }
}
