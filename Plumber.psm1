try {
    Import-Module InvokeBuild -ErrorAction 'Stop'
}
catch {
}

Get-Content "$PSScriptRoot\Resource\RequiredModules.json" | 
    ConvertFrom-Json | 
    ForEach-Object {
        try {
            Import-Module -Name $_.Name -MinimumVersion $_.MinimumVersion
        }
        catch {
            throw (
                "Could not load $($_.Name) v$($_.MinimumVersion). " + 
                "Try installing with 'Install-Module $($_.Name) -Force'. Error: $_"
            )
        }
    }

Get-ChildItem "$PSScriptRoot\Public", "$PSScriptRoot\Private" | ForEach-Object {
    . $_.FullName
}

