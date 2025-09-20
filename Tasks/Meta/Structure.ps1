task Structure {
    $misplacedJson = Get-ChildItem $BuildRoot -Filter '*.json'
    if ($misplacedJson) {
        Write-Error "JSON files should be in Resource folder"
    }
}