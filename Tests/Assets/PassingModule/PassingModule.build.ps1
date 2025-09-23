$module = Import-Module Plumber -PassThru
Get-ChildItem "$($module.ModuleBase)\Tasks" -Recurse -File | ForEach-Object {. $_.FullName}

task -Name CodeCoverage -Jobs {
    # Do nothing - CC not working
}