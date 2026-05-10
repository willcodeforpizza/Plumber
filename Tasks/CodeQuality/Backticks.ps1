<#
    .SYNOPSIS
    Validates PowerShell files do not contain backticks
#>
Add-BuildTask -Name Backticks -Jobs {
    $powershellFiles = Get-ChildItem $BuildRoot -File -Recurse |
        Where-Object {$_.Extension -in '.ps1', '.psd1', '.psm1'}

    $failures = foreach ($file in $powershellFiles) {
        $lineNumber = 0
        foreach ($line in Get-Content $file.FullName) {
            $lineNumber++
            if ($line.Contains([char] 96)) {
                "$($file.Name):$lineNumber - Backtick found"
            }
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
