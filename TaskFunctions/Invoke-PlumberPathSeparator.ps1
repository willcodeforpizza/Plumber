function Invoke-PlumberPathSeparator {
    <#
        .SYNOPSIS
        Runs the PathSeparator task body.
    #>
    [CmdletBinding()]
    param ()

    $extensions = '.ps1', '.psm1', '.psd1'
    $files = Get-PlumberTaskFile -Task PathSeparator -Extension $extensions

    $failures = foreach ($file in $files) {
        foreach ($hit in Get-PlumberPathSeparator -Path $file.FullName) {
            "$($file.Name):$($hit.Line) - Windows path separator in literal: $($hit.Text)"
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
