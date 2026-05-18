function Invoke-PlumberToDo {
    <#
        .SYNOPSIS
        Runs the ToDo task body.
    #>
    [CmdletBinding()]
    param ()

    $extensions = '.ps1', '.psm1', '.psd1'
    $taskFiles = Get-PlumberTaskFile -Task ToDo -Extension $extensions |
        Where-Object {$_.Name -ne 'ToDo.ps1'}

    $toDos = foreach ($file in $taskFiles) {
        try {
            $hits = Get-PlumberToDoComment -Path $file.FullName
        } catch {
            "$($file.Name): could not parse file: $($_.Exception.Message)"
            continue
        }
        foreach ($hit in $hits) {
            "$($file.Name):$($hit.Line) - $($hit.Message)".TrimEnd(' -')
        }
    }

    if ($toDos) {
        Write-Error ($toDos -join (', ' + [Environment]::NewLine))
    }
}
