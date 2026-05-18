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
    It 'passes when function files contain one matching function' {
        $moduleRoot = Initialize-TestModuleFixture -Name 'FunctionFileModule' -FunctionsToExport @('Get-Thing')
        Set-Content -Path (Join-Path $moduleRoot 'Public/Get-Thing.ps1') -Value @(
            'function Get-Thing {'
            '}'
        )
        Set-Content -Path (Join-Path $moduleRoot 'Private/Invoke-Helper.ps1') -Value @(
            'function Invoke-Helper {'
            '}'
        )

        & $script:invokeBuild -Task FunctionFiles -File "$moduleRoot/FunctionFileModule.build.ps1"
    }

    It 'fails when a function file contains multiple functions' {
        $moduleRoot = Initialize-TestModuleFixture -Name 'MultiFunctionModule' -FunctionsToExport @('Get-Thing')
        Set-Content -Path (Join-Path $moduleRoot 'Private/Invoke-Helper.ps1') -Value @(
            'function Invoke-Helper {'
            '}'
            ''
            'function Test-Helper {'
            '}'
        )

        {
            & $script:invokeBuild -Task FunctionFiles -File "$moduleRoot/MultiFunctionModule.build.ps1"
        } | Should -Throw -ExpectedMessage '*Private/Invoke-Helper.ps1 defines 2 functions; expected 1*'
    }

    It 'fails when a function file name does not match the function' {
        $moduleRoot = Initialize-TestModuleFixture -Name 'WrongNameModule' -FunctionsToExport @('Get-Thing')
        Set-Content -Path (Join-Path $moduleRoot 'Private/Invoke-Helper.ps1') -Value @(
            'function Test-Helper {'
            '}'
        )

        {
            & $script:invokeBuild -Task FunctionFiles -File "$moduleRoot/WrongNameModule.build.ps1"
        } | Should -Throw -ExpectedMessage '*Private/Invoke-Helper.ps1 defines function Test-Helper*'
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
