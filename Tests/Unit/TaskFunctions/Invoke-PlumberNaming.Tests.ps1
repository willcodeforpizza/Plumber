BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberNaming' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'NamingModule'
        Remove-Item -Path $script:buildRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $script:buildRoot -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $script:buildRoot 'NamingModule.psm1') -Value ''
    }

    It 'passes when RootModule casing matches the module file name' {
        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:moduleName = 'NamingModule'
            $script:psd1 = @{
                RootModule = 'NamingModule.psm1'
            }

            { Invoke-PlumberNaming -ErrorAction Stop } | Should -Not -Throw
        }
    }

    It 'fails when RootModule casing does not match the module file name' {
        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:moduleName = 'NamingModule'
            $script:psd1 = @{
                RootModule = 'namingmodule.psm1'
            }

            { Invoke-PlumberNaming -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*NamingModule.psm1 case does not match RootModule*'
        }
    }
}
