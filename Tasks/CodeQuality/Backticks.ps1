<#
    .SYNOPSIS
    Validates PowerShell files do not use line-continuation backticks.
#>
Add-BuildTask -Name Backticks -Jobs {
    $powershellFiles = Get-ChildItem $BuildRoot -File -Recurse |
        Where-Object {$_.Extension -in '.ps1', '.psd1', '.psm1'}

    $failures = foreach ($file in $powershellFiles) {
        $lineNumber = 0
        foreach ($line in Get-Content $file.FullName) {
            $lineNumber++
            if ($line -match '`\s*$') {
                "$($file.Name):$lineNumber - Line-continuation backtick found"
            }
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
