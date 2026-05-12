BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }

    $script:invokeBuild = Get-Command Invoke-Build

    function Initialize-TestModuleFixture {
        param (
            [Parameter(Mandatory)]
            [string]
            $Name,

            [Parameter(Mandatory)]
            [string[]]
            $FunctionsToExport
        )

        $moduleRoot = Join-Path $TestDrive $Name
        New-Item -Path (Join-Path $moduleRoot 'Public') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $moduleRoot 'Private') -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $moduleRoot "$Name.psd1") -Value @(
            '@{'
            "    RootModule = '$Name.psm1'"
            "    ModuleVersion = '0.0.1'"
            "    GUID = '11111111-1111-1111-1111-111111111111'"
            "    FunctionsToExport = @('$($FunctionsToExport -join "', '")')"
            '}'
        )
        Set-Content -Path (Join-Path $moduleRoot "$Name.psm1") -Value ''
        Set-Content -Path (Join-Path $moduleRoot "$Name.build.ps1") -Value @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = '$Name.psd1'"
            '}'
        )

        $moduleRoot
    }
}

Describe 'Module convention integration' {
    It 'passes when public files, functions and exports match' {
        $moduleRoot = Initialize-TestModuleFixture -Name 'MatchingModule' -FunctionsToExport @('Get-Thing')
        Set-Content -Path (Join-Path $moduleRoot 'Public/Get-Thing.ps1') -Value @(
            'function Get-Thing {'
            '}'
        )
        Set-Content -Path (Join-Path $moduleRoot 'Private/Invoke-Helper.ps1') -Value @(
            'function Invoke-Helper {'
            '}'
        )

        & $script:invokeBuild -Task PublicFunctions -File "$moduleRoot/MatchingModule.build.ps1"
    }

    It 'fails when a public function file is not exported' {
        $moduleRoot = Initialize-TestModuleFixture -Name 'MissingExportModule' -FunctionsToExport @('Get-Thing')
        Set-Content -Path (Join-Path $moduleRoot 'Public/Get-Thing.ps1') -Value @(
            'function Get-Thing {'
            '}'
        )
        Set-Content -Path (Join-Path $moduleRoot 'Public/Get-OtherThing.ps1') -Value @(
            'function Get-OtherThing {'
            '}'
        )

        {
            & $script:invokeBuild -Task PublicFunctions -File "$moduleRoot/MissingExportModule.build.ps1"
        } | Should -Throw -ExpectedMessage '*Get-OtherThing is not in FunctionsToExport*'
    }

    It 'fails when an exported function has no public file' {
        $moduleRoot = Initialize-TestModuleFixture -Name 'MissingFileModule' -FunctionsToExport @('Get-Thing')

        {
            & $script:invokeBuild -Task PublicFunctions -File "$moduleRoot/MissingFileModule.build.ps1"
        } | Should -Throw -ExpectedMessage '*Get-Thing is exported but Public/Get-Thing.ps1 was not found*'
    }

    It 'fails when a public file does not define its matching function' {
        $moduleRoot = Initialize-TestModuleFixture -Name 'WrongFunctionModule' -FunctionsToExport @('Get-Thing')
        Set-Content -Path (Join-Path $moduleRoot 'Public/Get-Thing.ps1') -Value @(
            'function Get-OtherThing {'
            '}'
        )

        {
            & $script:invokeBuild -Task PublicFunctions -File "$moduleRoot/WrongFunctionModule.build.ps1"
        } | Should -Throw -ExpectedMessage '*Get-Thing.ps1 does not define function Get-Thing*'
    }

    It 'fails when a private function is exported' {
        $moduleRoot = Initialize-TestModuleFixture -Name 'PrivateExportModule' -FunctionsToExport @('Get-Thing')
        Set-Content -Path (Join-Path $moduleRoot 'Public/Get-Thing.ps1') -Value @(
            'function Get-Thing {'
            '}'
        )
        Set-Content -Path (Join-Path $moduleRoot 'Private/Invoke-Helper.ps1') -Value @(
            'function Invoke-Helper {'
            '}'
        )
        $manifestPath = Join-Path $moduleRoot 'PrivateExportModule.psd1'
        Set-Content -Path $manifestPath -Value @(
            '@{'
            "    RootModule = 'PrivateExportModule.psm1'"
            "    ModuleVersion = '0.0.1'"
            "    GUID = '11111111-1111-1111-1111-111111111111'"
            "    FunctionsToExport = @('Get-Thing', 'Invoke-Helper')"
            '}'
        )

        {
            & $script:invokeBuild -Task PublicFunctions -File "$moduleRoot/PrivateExportModule.build.ps1"
        } | Should -Throw -ExpectedMessage '*Invoke-Helper is exported from Private/Invoke-Helper.ps1*'
    }
}
