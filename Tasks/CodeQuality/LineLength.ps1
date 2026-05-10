<#
    .SYNOPSIS
    Validates text files do not exceed the configured line length
#>
Add-BuildTask -Name LineLength -Jobs {
    # Scope can be lost when running Plumber on Plumber multiple times
    if (-not (Get-Command Get-PlumberTaskFile -ErrorAction SilentlyContinue)) {
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Test-PlumberTaskPathExcluded.ps1')
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberTaskFile.ps1')
    }

    $extensions = '.ps1', '.psm1', '.psd1'
    $files = Get-PlumberTaskFile -Task LineLength -Extension $extensions

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
