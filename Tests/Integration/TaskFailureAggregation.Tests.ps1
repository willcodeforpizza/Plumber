BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }

    # Runs a single Plumber task through a real Invoke-Plumber build in a
    # fresh pwsh process. Function-level tests cannot catch Write-Error
    # promotion under Invoke-Build's ErrorActionPreference Stop, so
    # report-all-failures behaviour must be asserted at this level.
    function Invoke-PlumberTaskRun {
        param (
            [string]
            $ModuleRoot,

            [string]
            $Task
        )

        $modulePath = (Resolve-Path "$PSScriptRoot/../../Plumber.psd1").Path.Replace("'", "''")
        $moduleRootLiteral = $ModuleRoot.Replace("'", "''")
        $command = @"
Import-Module '$modulePath' -Force
Push-Location '$moduleRootLiteral'
Invoke-Plumber -Task $Task -OutputMode Summary -NoFormat
"@

        $output = & (Get-Command pwsh).Source -NoLogo -NoProfile -Command $command 2>&1 |
            Out-String

        [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = $output
        }
    }

    function New-AggregationFixtureModule {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseShouldProcessForStateChangingFunctions',
            '',
            Justification = 'Creates throwaway TestDrive fixtures only.'
        )]
        [CmdletBinding()]
        param (
            [string]
            $Name
        )

        $moduleRoot = Join-Path $TestDrive $Name
        Remove-Item -Path $moduleRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path (Join-Path $moduleRoot 'Resource') -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $moduleRoot "$Name.psd1") -Value @(
            '@{'
            "    ModuleVersion = '0.1.0'"
            '}'
        )
        $moduleRoot
    }
}

Describe 'Task failure aggregation through Invoke-Plumber' {
    It 'JSON task reports every invalid file in a real build run' {
        $moduleRoot = New-AggregationFixtureModule -Name 'JsonAggregationModule'
        Set-Content -Path (Join-Path $moduleRoot 'Resource/invalid-one.json') -Value '{"name":'
        Set-Content -Path (Join-Path $moduleRoot 'Resource/invalid-two.json') -Value '[1,'
        Set-Content -Path (Join-Path $moduleRoot 'JsonAggregationModule.build.ps1') -Value @(
            '. (Get-PlumberTaskLoader) -Config @{}'
        )

        $result = Invoke-PlumberTaskRun -ModuleRoot $moduleRoot -Task JSON

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -BeLike '*invalid-one.json*'
        $result.Output | Should -BeLike '*invalid-two.json*'
    }

    It 'YAML task reports every invalid file in a real build run' {
        $moduleRoot = New-AggregationFixtureModule -Name 'YamlAggregationModule'
        Set-Content -Path (Join-Path $moduleRoot 'Resource/invalid-one.yml') -Value @(
            'name: build'
            '  bad-indent: true'
        )
        Set-Content -Path (Join-Path $moduleRoot 'Resource/invalid-two.yml') -Value @(
            'steps:'
            '  - task: validate'
            '    invalid'
        )
        Set-Content -Path (Join-Path $moduleRoot 'YamlAggregationModule.build.ps1') -Value @(
            '. (Get-PlumberTaskLoader) -Config @{}'
        )

        $result = Invoke-PlumberTaskRun -ModuleRoot $moduleRoot -Task YAML

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -BeLike '*invalid-one.yml*'
        $result.Output | Should -BeLike '*invalid-two.yml*'
    }

    It 'PublicFunctions task reports every failure as a separate entry in a real build run' {
        $moduleRoot = Join-Path $TestDrive 'PublicFunctionsAggregationModule'
        Remove-Item -Path $moduleRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path (Join-Path $moduleRoot 'Public') -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $moduleRoot 'PublicFunctionsAggregationModule.psd1') -Value @(
            '@{'
            "    ModuleVersion     = '0.1.0'"
            "    FunctionsToExport = @('Get-Thing')"
            '}'
        )
        Set-Content -Path (Join-Path $moduleRoot 'Public/Get-OtherThing.ps1') -Value @(
            'function Get-OtherThing {'
            '}'
        )
        Set-Content -Path (Join-Path $moduleRoot 'PublicFunctionsAggregationModule.build.ps1') -Value @(
            '. (Get-PlumberTaskLoader) -Config @{}'
        )

        $result = Invoke-PlumberTaskRun -ModuleRoot $moduleRoot -Task PublicFunctions

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -BeLike '*Get-OtherThing is not in FunctionsToExport,*'
        $result.Output | Should -BeLike '*Get-Thing is exported but Public/Get-Thing.ps1 was not found*'
    }

    It 'JSONSchema task reports every schema-invalid file in a real build run' {
        $moduleRoot = New-AggregationFixtureModule -Name 'SchemaAggregationModule'
        New-Item -Path (Join-Path $moduleRoot 'Resource/Schema') -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $moduleRoot 'Resource/Schema/config.schema.json') -Value @'
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "required": ["name"],
    "properties": {
        "name": {
            "type": "string"
        }
    }
}
'@
        Set-Content -Path (Join-Path $moduleRoot 'Resource/invalid-one.json') -Value '{"name":1}'
        Set-Content -Path (Join-Path $moduleRoot 'Resource/invalid-two.json') -Value '{"other":true}'
        Set-Content -Path (Join-Path $moduleRoot 'SchemaAggregationModule.build.ps1') -Value @(
            '. (Get-PlumberTaskLoader) -Config @{'
            '    Tasks = @{'
            '        JSONSchema = @{'
            "            Exclude = @('Resource/Schema/*.json')"
            '            Schemas = @('
            '                @{'
            "                    Path   = 'Resource/**/*.json'"
            "                    Schema = 'Resource/Schema/config.schema.json'"
            '                }'
            '            )'
            '        }'
            '    }'
            '}'
        )

        $result = Invoke-PlumberTaskRun -ModuleRoot $moduleRoot -Task JSONSchema

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -BeLike '*invalid-one.json*'
        $result.Output | Should -BeLike '*invalid-two.json*'
    }
}
