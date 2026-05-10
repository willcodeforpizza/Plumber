<#
    .SYNOPSIS
    Validates no #TODOs are left as code comments
#>
Add-BuildTask -Name ToDo -Jobs {
    if (-not (Get-Command Test-PlumberTaskPathExcluded -ErrorAction SilentlyContinue)) {
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Test-PlumberTaskPathExcluded.ps1')
    }

    $toDos = Get-ChildItem $BuildRoot -File -Recurse -Exclude 'ToDo.ps1' |
        Where-Object {-not (Test-PlumberTaskPathExcluded -Task ToDo -Path $_.FullName)} |
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
