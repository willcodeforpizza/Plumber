BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberLineLength' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'LineLengthModule'
        $publicRoot = Join-Path $script:buildRoot 'Public'
        New-Item -Path $publicRoot -ItemType Directory -Force | Out-Null
    }

    It 'reports lines over the configured maximum length' {
        $longLine = 'x' * 11
        Set-Content -Path (Join-Path $script:buildRoot 'Public/Invoke-Thing.ps1') -Value @(
            'function Invoke-Thing {'
            "    '$longLine'"
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
                    LineLength = @{
                        MaxLength = 10
                    }
                }
            }

            { Invoke-PlumberLineLength -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Invoke-Thing.ps1:2 - Line is 17 characters >10*'
        }
    }

    It 'does not report lines at or below the configured maximum length' {
        Set-Content -Path (Join-Path $script:buildRoot 'Public/Invoke-Thing.ps1') -Value @(
            'function Invoke-Thing {'
            "    'short'"
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
                    LineLength = @{
                        MaxLength = 25
                    }
                }
            }

            { Invoke-PlumberLineLength -ErrorAction Stop } | Should -Not -Throw
        }
    }
}
