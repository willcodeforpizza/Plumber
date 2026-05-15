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
            $FunctionsToExport,

            [string[]]
            $ConfigLines = @()
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
        $buildConfigLines = @("    ModuleManifest = '$Name.psd1'") + $ConfigLines
        Set-Content -Path (Join-Path $moduleRoot "$Name.build.ps1") -Value @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            $buildConfigLines
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

    It 'passes when public functions use the module name as the default prefix' {
        $moduleRoot = Initialize-TestModuleFixture -Name 'ThingDefault' -FunctionsToExport @(
            'Get-ThingDefaultItem'
        )
        Set-Content -Path (Join-Path $moduleRoot 'Public/Get-ThingDefaultItem.ps1') -Value @(
            'function Get-ThingDefaultItem {'
            '}'
        )

        & $script:invokeBuild -Task PublicFunctionPrefix -File "$moduleRoot/ThingDefault.build.ps1"
    }

    It 'fails when a public function does not use the default prefix' {
        $moduleRoot = Initialize-TestModuleFixture -Name 'ThingFail' -FunctionsToExport @('Get-Item')
        Set-Content -Path (Join-Path $moduleRoot 'Public/Get-Item.ps1') -Value @(
            'function Get-Item {'
            '}'
        )

        {
            & $script:invokeBuild -Task PublicFunctionPrefix -File "$moduleRoot/ThingFail.build.ps1"
        } | Should -Throw -ExpectedMessage "*Get-Item does not use public function prefix 'ThingFail'*"
    }

    It 'uses the configured public function prefix' {
        $fixtureSplat = @{
            Name              = 'CustomModule'
            FunctionsToExport = @('Get-CustomItem')
            ConfigLines       = @(
                '    Tasks = @{'
                "        PublicFunctionPrefix = @{ Prefix = 'Custom' }"
                '    }'
            )
        }
        $moduleRoot = Initialize-TestModuleFixture @fixtureSplat
        Set-Content -Path (Join-Path $moduleRoot 'Public/Get-CustomItem.ps1') -Value @(
            'function Get-CustomItem {'
            '}'
        )

        & $script:invokeBuild -Task PublicFunctionPrefix -File "$moduleRoot/CustomModule.build.ps1"
    }

    It 'excludes configured public functions from prefix validation' {
        $moduleRoot = Initialize-TestModuleFixture -Name 'ThingExcluded' -FunctionsToExport @(
            'Get-ThingExcludedItem',
            'New-Item'
        ) -ConfigLines @(
            '    Tasks = @{'
            "        PublicFunctionPrefix = @{ Exclusions = @('New-Item') }"
            '    }'
        )
        Set-Content -Path (Join-Path $moduleRoot 'Public/Get-ThingExcludedItem.ps1') -Value @(
            'function Get-ThingExcludedItem {'
            '}'
        )
        Set-Content -Path (Join-Path $moduleRoot 'Public/New-Item.ps1') -Value @(
            'function New-Item {'
            '}'
        )

        & $script:invokeBuild -Task PublicFunctionPrefix -File "$moduleRoot/ThingExcluded.build.ps1"
    }
}
