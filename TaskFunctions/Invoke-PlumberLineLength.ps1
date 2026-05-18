function Invoke-PlumberLineLength {
    <#
        .SYNOPSIS
        Runs the LineLength task body.
    #>
    [CmdletBinding()]
    param ()

    $extensions = '.ps1', '.psm1', '.psd1'
    $files = Get-PlumberTaskFile -Task LineLength -Extension $extensions

    $failures = foreach ($file in $files) {
        $lineNumber = 0
        foreach ($line in Get-Content $file.FullName) {
            $lineNumber++
            if ($line.Length -gt $script:PlumberConfig.Tasks.LineLength.MaxLength) {
                (
                    "$($file.Name):$lineNumber - " +
                    "Line is $($line.Length) characters " +
                    ">$($script:PlumberConfig.Tasks.LineLength.MaxLength)"
                )
            }
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
