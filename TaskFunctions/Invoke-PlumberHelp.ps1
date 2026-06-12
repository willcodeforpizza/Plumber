function Invoke-PlumberHelp {
    <#
        .SYNOPSIS
        Runs the Help task body.
    #>
    [CmdletBinding()]
    param ()

    $publicRoot = Join-Path $BuildRoot 'Public'
    $pathComparison = Get-PlumberPathStringComparison
    $functionRoots = [System.Collections.Generic.List[hashtable]]::new()
    $functionRoots.Add(@{
        Path            = $publicRoot
        RequireFullHelp = $true
    })
    foreach ($moduleFolder in $script:moduleFolders) {
        if ($moduleFolder.Equals($publicRoot, $pathComparison)) {
            continue
        }

        $functionRoots.Add(@{
            Path            = $moduleFolder
            RequireFullHelp = -not $script:PlumberConfig.Tasks.Help.PrivateSynopsisOnly
        })
    }

    $failures = [System.Collections.Generic.List[string]]::new()
    foreach ($functionRoot in $functionRoots) {
        if (-not (Test-Path $functionRoot.Path)) {
            continue
        }

        foreach ($file in Get-ChildItem $functionRoot.Path -File -Filter '*.ps1') {
            $help = Get-PlumberFunctionHelp -Path $file.FullName
            $helpFailures = Test-PlumberFunctionHelp -Help $help -RequireFullHelp:$functionRoot.RequireFullHelp
            foreach ($helpFailure in $helpFailures) {
                $failures.Add($helpFailure)
            }
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
