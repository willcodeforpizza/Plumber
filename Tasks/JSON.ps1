task JSON {
    $jsonFiles = Get-ChildItem "$BuildRoot\Resource" -File -Filter '*.json'
    if (-not $jsonFiles) {
        Write-Build Yellow "No JSON files found"
        return
    }

    foreach ($jsonFile in $jsonFiles) {
        $name = ($jsonFile | Split-Path -Leaf) -Replace '.json'
        $schema = (Get-Content "$BuildRoot\Resource\Schema\$name`Schema.json" -Raw)  
        if (-not (Test-Json -Path $jsonFile -Schema $schema)) {
            Write-Error "$jsonFile did not pass validation"
        }
    }
}
