try {
    Import-Module InvokeBUild -ErrorAction 'Stop'
}
catch {
    throw "Could not load InvokeBUild. Is it installed? Error: $_"
}

Get-ChildItem "$PSScriptRoot\Public", "$PSScriptRoot\Private" | ForEach-Object {
    write-host $_.FullName
    . $_.FullName
}

Get-Content "$PSScriptRoot\Resource\RequiredModules.json" | 
    ConvertFrom-Json | 
    ForEach-Object {Import-Module -Name $_.Name -MinimumVersion $_.MinimumVersion}