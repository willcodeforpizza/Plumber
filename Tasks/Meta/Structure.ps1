<#
    .SYNOPSIS
    Validates JSON files are not stored in the root of the module
#>
task Structure {
    $misplacedJson = Get-ChildItem $BuildRoot -Filter '*.json'
    if ($misplacedJson) {
        Write-Error "JSON files should be in Resource folder"
    }
}