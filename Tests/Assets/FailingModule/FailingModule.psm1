Get-ChildItem "$PSScriptRoot\Public", "$PSScriptRoot\Private" | ForEach-Object {. $_.FullName}
