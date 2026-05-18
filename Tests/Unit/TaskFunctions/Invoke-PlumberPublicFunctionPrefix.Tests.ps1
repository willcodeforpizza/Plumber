BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberPublicFunctionPrefix' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'PrefixModule'
        $script:publicRoot = Join-Path $script:buildRoot 'Public'
        Remove-Item -Path $script:buildRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $script:publicRoot -ItemType Directory -Force | Out-Null
    }

    It 'passes when public functions use the module name as the default prefix' {
        Set-Content -Path (Join-Path $script:publicRoot 'Get-PrefixModuleItem.ps1') -Value @(
            'function Get-PrefixModuleItem {'
            '}'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:moduleName = 'PrefixModule'
            $script:PlumberConfig = @{
                Tasks = @{
                    PublicFunctionPrefix = @{
                        Prefix     = $null
                        Exclusions = @()
                    }
                }
            }

            { Invoke-PlumberPublicFunctionPrefix -ErrorAction Stop } | Should -Not -Throw
        }
    }

    It 'fails when a public function does not use the default prefix' {
        Set-Content -Path (Join-Path $script:publicRoot 'Get-Item.ps1') -Value @(
            'function Get-Item {'
            '}'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:moduleName = 'PrefixModule'
            $script:PlumberConfig = @{
                Tasks = @{
                    PublicFunctionPrefix = @{
                        Prefix     = $null
                        Exclusions = @()
                    }
                }
            }

            { Invoke-PlumberPublicFunctionPrefix -ErrorAction Stop } |
                Should -Throw -ExpectedMessage "*Get-Item does not use public function prefix 'PrefixModule'*"
        }
    }

    It 'uses the configured public function prefix' {
        Set-Content -Path (Join-Path $script:publicRoot 'Get-CustomItem.ps1') -Value @(
            'function Get-CustomItem {'
            '}'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:moduleName = 'PrefixModule'
            $script:PlumberConfig = @{
                Tasks = @{
                    PublicFunctionPrefix = @{
                        Prefix     = 'Custom'
                        Exclusions = @()
                    }
                }
            }

            { Invoke-PlumberPublicFunctionPrefix -ErrorAction Stop } | Should -Not -Throw
        }
    }

    It 'excludes configured public functions from prefix validation' {
        Set-Content -Path (Join-Path $script:publicRoot 'Get-PrefixModuleItem.ps1') -Value @(
            'function Get-PrefixModuleItem {'
            '}'
        )
        Set-Content -Path (Join-Path $script:publicRoot 'New-Item.ps1') -Value @(
            'function New-Item {'
            '}'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:moduleName = 'PrefixModule'
            $script:PlumberConfig = @{
                Tasks = @{
                    PublicFunctionPrefix = @{
                        Prefix     = $null
                        Exclusions = @('New-Item')
                    }
                }
            }

            { Invoke-PlumberPublicFunctionPrefix -ErrorAction Stop } | Should -Not -Throw
        }
    }
}
