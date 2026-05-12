$script:moduleRoot = $PSScriptRoot

$manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Plumber.psd1')
foreach ($requiredModule in $manifest.ModuleList) {
    try {
        $name = $requiredModule.ModuleName
        $version = $requiredModule.ModuleVersion
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
