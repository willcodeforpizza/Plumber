BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberPublicFunctions' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'PublicFunctionModule'
        $script:publicRoot = Join-Path $script:buildRoot 'Public'
        $script:privateRoot = Join-Path $script:buildRoot 'Private'
        Remove-Item -Path $script:buildRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $script:publicRoot, $script:privateRoot -ItemType Directory -Force |
            Out-Null
    }

    It 'passes when public files, functions and exports match' {
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
            $script:psd1 = @{
                FunctionsToExport = @('Get-Thing')
            }
            $script:moduleFolders = @($PublicRoot, $PrivateRoot)

            { Invoke-PlumberPublicFunctions -ErrorAction Stop } | Should -Not -Throw
        }
    }

    It 'fails when a public function file is not exported' {
        Set-Content -Path (Join-Path $script:publicRoot 'Get-Thing.ps1') -Value @(
            'function Get-Thing {'
            '}'
        )
        Set-Content -Path (Join-Path $script:publicRoot 'Get-OtherThing.ps1') -Value @(
            'function Get-OtherThing {'
            '}'
        )

        InModuleScope Plumber -Parameters @{
            BuildRoot = $script:buildRoot
            PublicRoot = $script:publicRoot
            PrivateRoot = $script:privateRoot
        } {
            $script:psd1 = @{
                FunctionsToExport = @('Get-Thing')
            }
            $script:moduleFolders = @($PublicRoot, $PrivateRoot)

            { Invoke-PlumberPublicFunctions -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Get-OtherThing is not in FunctionsToExport*'
        }
    }

    It 'fails when an exported function has no public file' {
        InModuleScope Plumber -Parameters @{
            BuildRoot = $script:buildRoot
            PublicRoot = $script:publicRoot
            PrivateRoot = $script:privateRoot
        } {
            $script:psd1 = @{
                FunctionsToExport = @('Get-Thing')
            }
            $script:moduleFolders = @($PublicRoot, $PrivateRoot)

            { Invoke-PlumberPublicFunctions -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Get-Thing is exported but Public/Get-Thing.ps1 was not found*'
        }
    }

    It 'fails when a public file does not define its matching function' {
        Set-Content -Path (Join-Path $script:publicRoot 'Get-Thing.ps1') -Value @(
            'function Get-OtherThing {'
            '}'
        )

        InModuleScope Plumber -Parameters @{
            BuildRoot = $script:buildRoot
            PublicRoot = $script:publicRoot
            PrivateRoot = $script:privateRoot
        } {
            $script:psd1 = @{
                FunctionsToExport = @('Get-Thing')
            }
            $script:moduleFolders = @($PublicRoot, $PrivateRoot)

            { Invoke-PlumberPublicFunctions -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Get-Thing.ps1 does not define function Get-Thing*'
        }
    }

    It 'fails when a private function is exported' {
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
            $script:psd1 = @{
                FunctionsToExport = @('Get-Thing', 'Invoke-Helper')
            }
            $script:moduleFolders = @($PublicRoot, $PrivateRoot)

            { Invoke-PlumberPublicFunctions -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Invoke-Helper is exported from Private/Invoke-Helper.ps1*'
        }
    }

    It 'does not treat a differently-cased Public directory as Public on Linux' {
        $caseVariantPublicRoot = Join-Path $script:buildRoot 'public'
        New-Item -Path $caseVariantPublicRoot -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $script:publicRoot 'Get-Thing.ps1') -Value @(
            'function Get-Thing {'
            '}'
        )
        Set-Content -Path (Join-Path $caseVariantPublicRoot 'Invoke-Helper.ps1') -Value @(
            'function Invoke-Helper {'
            '}'
        )

        InModuleScope Plumber -Parameters @{
            BuildRoot             = $script:buildRoot
            PublicRoot            = $script:publicRoot
            CaseVariantPublicRoot = $caseVariantPublicRoot
        } {
            $script:psd1 = @{
                FunctionsToExport = @('Get-Thing', 'Invoke-Helper')
            }
            $script:moduleFolders = @($PublicRoot, $CaseVariantPublicRoot)

            if ($IsLinux) {
                { Invoke-PlumberPublicFunctions -ErrorAction Stop } |
                    Should -Throw -ExpectedMessage '*Invoke-Helper is exported from public/Invoke-Helper.ps1*'
            } else {
                { Invoke-PlumberPublicFunctions -ErrorAction Stop } | Should -Not -Throw
            }
        }
    }
}
