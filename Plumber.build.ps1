#TODO: Remove hardcoded path
$module = Import-Module C:\gh\Plumber\Plumber.psd1 -PassThru
Get-ChildItem "$($module.ModuleBase)\Tasks" -Recurse -File | ForEach-Object {. $_.FullName}

task Structure {
    #TODO: Example
    Write-Build Yellow "Bypassing structure for legacy module"
}