$module = Import-Module Plumber -PassThru
Get-ChildItem "$($module.ModuleBase)\Tasks" -Recurse -File |
    ForEach-Object {. $_.FullName}