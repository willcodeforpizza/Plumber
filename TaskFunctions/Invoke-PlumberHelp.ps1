function Invoke-PlumberHelp {
    <#
        .SYNOPSIS
        Runs the Help task body.
    #>
    [CmdletBinding()]
    param ()

    $publicRoot = Join-Path $BuildRoot 'Public'
    $functionRoots = @(
        @{
            Path            = $publicRoot
            RequireFullHelp = $true
        }
    )
    $functionRoots += foreach ($moduleFolder in $script:moduleFolders) {
        if ($moduleFolder.Equals($publicRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        @{
            Path            = $moduleFolder
            RequireFullHelp = -not $script:PlumberConfig.Tasks.Help.PrivateSynopsisOnly
        }
    }

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
