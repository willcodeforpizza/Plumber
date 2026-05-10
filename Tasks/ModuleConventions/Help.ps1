<#
    .SYNOPSIS
    Validates public and private function help
#>
Add-BuildTask -Name Help -Jobs {
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberFunctionHelp.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Test-PlumberFunctionHelp.ps1')

    $functionRoots = @(
        @{
            Path            = Join-Path $BuildRoot 'Public'
            RequireFullHelp = $true
        }
        @{
            Path            = Join-Path $BuildRoot 'Private'
            RequireFullHelp = -not $script:PlumberConfig.PrivateHelpSynopsisOnly
        }
    )

    $failures = foreach ($functionRoot in $functionRoots) {
        if (-not (Test-Path $functionRoot.Path)) {
            continue
        }

        foreach ($file in Get-ChildItem $functionRoot.Path -File -Filter '*.ps1') {
            $help = Get-PlumberFunctionHelp -Path $file.FullName
            Test-PlumberFunctionHelp -Help $help -RequireFullHelp:$functionRoot.RequireFullHelp
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
