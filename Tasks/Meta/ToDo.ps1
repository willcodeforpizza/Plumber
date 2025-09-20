task ToDo {
    $toDos = Get-ChildItem $BuildRoot -File -Recurse -Exclude 'ToDo.ps1' | ForEach-Object {
        $file = $_
        Get-Content $_.FullName | Where-Object {$_ -match '#TODO'} | ForEach-Object {
            "$($file.Name): $(($_ -replace '#TODO: ').Trim())"
        }
    }
    Write-Error ($toDos -join  (', ' + [Environment]::NewLine))
}
