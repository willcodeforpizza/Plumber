<#
    .SYNOPSIS
    Validates no #TODOs are left as code comments
#>
Add-BuildTask -Name ToDo -Jobs {
    if (-not (Get-Command Get-PlumberTaskFile -ErrorAction SilentlyContinue)) {
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Test-PlumberTaskPathExcluded.ps1')
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberTaskFile.ps1')
    }

    $toDos = Get-PlumberTaskFile -Task ToDo |
        Where-Object {$_.Name -ne 'ToDo.ps1'} |
        ForEach-Object {
        $file = $_
        Get-Content $_.FullName | Where-Object { $_ -match '#TODO' } | ForEach-Object {
            "$($file.Name): $(($_ -replace '#TODO: ').Trim())"
        }
    }
    if ($toDos) {
        Write-Error ($toDos -join (', ' + [Environment]::NewLine))
    }
}
