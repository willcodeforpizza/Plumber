BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberFunctionFiles' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'FunctionFileModule'
        $script:publicRoot = Join-Path $script:buildRoot 'Public'
        $script:privateRoot = Join-Path $script:buildRoot 'Private'
        Remove-Item -Path $script:buildRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $script:publicRoot, $script:privateRoot -ItemType Directory -Force |
            Out-Null
    }

    It 'passes when function files contain one matching function' {
        Set-Content -Path (Join-Path $script:publicRoot 'Get-Thing.ps1') -Value @(
            'function Get-Thing {'
            '}'
        )
        Set-Content -Path (Join-Path $script:privateRoot 'Invoke-Helper.ps1') -Value @(
            'function Invoke-Helper {'
            '}'
        )

        InModuleScope Plumber -Parameters @{
            BuildRoot = $script:buildRoot
            PublicRoot = $script:publicRoot
            PrivateRoot = $script:privateRoot
        } {
            $script:moduleFolders = @($PublicRoot, $PrivateRoot)
            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    FunctionFiles = @{
                        Exclude = @()
                    }
                }
            }

            { Invoke-PlumberFunctionFiles -ErrorAction Stop } | Should -Not -Throw
        }
    }

    It 'fails when a function file contains multiple functions' {
        Set-Content -Path (Join-Path $script:privateRoot 'Invoke-Helper.ps1') -Value @(
            'function Invoke-Helper {'
            '}'
            ''
            'function Test-Helper {'
            '}'
        )

        InModuleScope Plumber -Parameters @{
            BuildRoot = $script:buildRoot
            PublicRoot = $script:publicRoot
            PrivateRoot = $script:privateRoot
        } {
            $script:moduleFolders = @($PublicRoot, $PrivateRoot)
            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    FunctionFiles = @{
                        Exclude = @()
                    }
                }
            }

            { Invoke-PlumberFunctionFiles -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Private/Invoke-Helper.ps1 defines 2 functions; expected 1*'
        }
    }

    It 'fails when a function file name does not match the function' {
        Set-Content -Path (Join-Path $script:privateRoot 'Invoke-Helper.ps1') -Value @(
            'function Test-Helper {'
            '}'
        )

        InModuleScope Plumber -Parameters @{
            BuildRoot = $script:buildRoot
            PublicRoot = $script:publicRoot
            PrivateRoot = $script:privateRoot
        } {
            $script:moduleFolders = @($PublicRoot, $PrivateRoot)
            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    FunctionFiles = @{
                        Exclude = @()
                    }
                }
            }

            { Invoke-PlumberFunctionFiles -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Private/Invoke-Helper.ps1 defines function Test-Helper*'
        }
    }
}
