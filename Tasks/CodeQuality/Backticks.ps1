<#
    .SYNOPSIS
    Validates PowerShell files do not use line-continuation backticks.
#>
Add-BuildTask -Name Backticks -Jobs {
    if (-not (Get-Command Test-PlumberTaskPathExcluded -ErrorAction SilentlyContinue)) {
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Test-PlumberTaskPathExcluded.ps1')
    }

    $powershellFiles = Get-ChildItem $BuildRoot -File -Recurse |
        Where-Object {
            $_.Extension -in '.ps1', '.psd1', '.psm1' -and
            -not (Test-PlumberTaskPathExcluded -Task Backticks -Path $_.FullName)
        }

    $failures = foreach ($file in $powershellFiles) {
        $lineNumber = 0
        foreach ($line in Get-Content $file.FullName) {
            $lineNumber++
            if ($line -match '(?<!`)`\s*$') {
                "$($file.Name):$lineNumber - Line-continuation backtick found"
            }
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
