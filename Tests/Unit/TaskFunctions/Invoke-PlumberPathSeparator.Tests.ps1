BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberPathSeparator' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'PathModule'
        $script:publicRoot = Join-Path $script:buildRoot 'Public'
        New-Item -Path $script:publicRoot -ItemType Directory -Force | Out-Null
    }

    It 'reports Windows path separators in string literals' {
        [char] $backslash = 92
        Set-Content -Path (Join-Path $script:publicRoot 'Invoke-Thing.ps1') -Value @(
            'function Invoke-Thing {'
            "    `$path = `"`$BuildRoot$($backslash)Tests$($backslash)Unit`""
            '}'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    PathSeparator = @{
                        Exclude = @()
                    }
                }
            }

            { Invoke-PlumberPathSeparator -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Invoke-Thing.ps1:2 - Windows path separator*'
        }
    }
}
