function Invoke-PlumberPublicFunctionPrefix {
    <#
        .SYNOPSIS
        Runs the PublicFunctionPrefix task body.
    #>
    [CmdletBinding()]
    param ()

    $prefix = if ($script:PlumberConfig.Tasks.PublicFunctionPrefix.Prefix) {
        $script:PlumberConfig.Tasks.PublicFunctionPrefix.Prefix
    } else {
        $script:moduleName
    }
    $exclusions = @($script:PlumberConfig.Tasks.PublicFunctionPrefix.Exclusions)
    $publicRoot = Join-Path $BuildRoot 'Public'
    if (-not (Test-Path $publicRoot)) {
        return
    }

    $failures = foreach ($publicFile in Get-ChildItem $publicRoot -File -Filter '*.ps1') {
        $functionName = $publicFile.BaseName
        if ($functionName -in $exclusions) {
            continue
        }

        $commandParts = $functionName -split '-', 2
        if ($commandParts.Count -ne 2 -or -not ($commandParts[1] -clike "$prefix*")) {
            "$functionName does not use public function prefix '$prefix'"
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
