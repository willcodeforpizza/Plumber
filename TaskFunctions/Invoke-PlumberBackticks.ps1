function Invoke-PlumberBackticks {
    <#
        .SYNOPSIS
        Runs the Backticks task body.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'Task body function matches the Backticks task name.'
    )]
    [CmdletBinding()]
    param ()

    $powershellFiles = Get-PlumberTaskFile -Task Backticks -Extension '.ps1', '.psd1', '.psm1'

    $failures = foreach ($file in $powershellFiles) {
        try {
            $hits = Get-PlumberLineContinuation -Path $file.FullName
        } catch {
            "$($file.Name):0 - Could not parse file: $($_.Exception.Message)"
            continue
        }
        foreach ($hit in $hits) {
            "$($file.Name):$($hit.Line) - Line-continuation backtick found"
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
