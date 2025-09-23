$module = Import-Module Plumber -PassThru
Get-ChildItem "$($module.ModuleBase)\Tasks" -Recurse -File -Filter '*.ps1' |
    ForEach-Object {. $_.FullName}