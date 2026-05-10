<#
    .SYNOPSIS
    Validates PowerShell files do not use line-continuation backticks.
#>
Add-BuildTask -Name Backticks -Jobs {
    # Scope can be lost when running Plumber on Plumber multiple times
    if (-not (Get-Command Get-PlumberTaskFile -ErrorAction SilentlyContinue)) {
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Test-PlumberTaskPathExcluded.ps1')
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberTaskFile.ps1')
    }

    $powershellFiles = Get-PlumberTaskFile -Task Backticks -Extension '.ps1', '.psd1', '.psm1'

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
