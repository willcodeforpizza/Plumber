<#
    .SYNOPSIS
    Validates text files do not exceed the configured line length
#>
Add-BuildTask -Name LineLength -Jobs {
    if (-not (Get-Command Test-PlumberTaskPathExcluded -ErrorAction SilentlyContinue)) {
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Test-PlumberTaskPathExcluded.ps1')
    }

    $extensions = '.ps1', '.psm1', '.psd1'
    $files = Get-ChildItem $BuildRoot -File -Recurse |
        Where-Object {
            $_.Extension -in $extensions -and
            -not (Test-PlumberTaskPathExcluded -Task LineLength -Path $_.FullName)
        }

    $failures = foreach ($file in $files) {
        $lineNumber = 0
        foreach ($line in Get-Content $file.FullName) {
            $lineNumber++
            if ($line.Length -gt $script:PlumberConfig.MaxLineLength) {
                (
                    "$($file.Name):$lineNumber - " +
                    "Line is $($line.Length) characters " +
                    ">$($script:PlumberConfig.MaxLineLength)"
                )
            }
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
