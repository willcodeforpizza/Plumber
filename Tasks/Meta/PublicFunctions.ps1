<#
    .SYNOPSIS
    Validates all public functions are declared in the PSD1
#>
task -Name PublicFunctions -Jobs {
    $failures = Get-ChildItem "$BuildRoot\Public" | ForEach-Object {
        if ($_.BaseName -notin $script:psd1.FunctionsToExport) {
            "$($_.BaseName) is not in FunctionsToExport"
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
