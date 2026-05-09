$script:moduleRoot = $PSScriptRoot

Get-Content "$PSScriptRoot\Resource\RequiredModules.json" |
    ConvertFrom-Json |
        ForEach-Object {
            try {
                $name = $_.Name
                $version = $_.MinimumVersion
                Import-Module -Name $name -MinimumVersion $version -ErrorAction Stop
            }
            catch {
                throw (
                    "Could not load $name v$version. " +
                    "Install with 'Install-Module $name -Scope CurrentUser -Force'. Error: $_"
                )
            }
        }

Get-ChildItem "$PSScriptRoot\Public", "$PSScriptRoot\Private" |
    ForEach-Object {. $_.FullName}
