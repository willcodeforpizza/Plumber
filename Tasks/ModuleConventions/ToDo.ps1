<#
    .SYNOPSIS
    Validates no TODO comments are left in files.
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
        Get-Content $_.FullName | Where-Object {$_ -match '^\s*#\s*TODO\b'} | ForEach-Object {
            "$($file.Name): $(($_ -replace '^\s*#\s*TODO:?\s*', '').Trim())"
        }
    }
    if ($toDos) {
        Write-Error ($toDos -join (', ' + [Environment]::NewLine))
    }
}
