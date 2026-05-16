BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberTaskLoader content integration' {
    BeforeAll {
        $script:invokeBuild = Get-Command Invoke-Build
    }

    It 'loads JSONSchema directly under Content' {
        $buildFile = Join-Path $TestDrive 'content.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'JSONSchema'
        $tasks['Content'].Jobs | Should -Contain '?JSONSchema'
    }

    It 'reports invalid nested JSON files' {
        $moduleRoot = Join-Path $TestDrive 'JsonModule'
        $resourceRoot = Join-Path $moduleRoot 'Resource/Nested'
        New-Item -Path $resourceRoot -ItemType Directory | Out-Null
        Set-Content -Path (Join-Path $resourceRoot 'config.json') -Value '{"name":'

        $buildFile = Join-Path $moduleRoot 'JsonModule.build.ps1'
        @(
            '$ErrorActionPreference = ''Stop'''
            "Set-Variable -Name BuildRoot -Value '$moduleRoot' -Scope Script"
            'function Add-BuildTask {'
            '    param ('
            '        [string]'
            '        $Name,'
            ''
            '        $Jobs'
            '    )'
            ''
            '    if ($Name -eq "JSON") {'
            '        & $Jobs'
            '    }'
            '}'
            'function Write-Build {'
            '    param ('
            '        $Color,'
            ''
            '        $Message'
            '    )'
            '}'
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{}'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile 2>&1 |
            Out-String

        $LASTEXITCODE | Should -Not -Be 0
        $result | Should -Match 'Invalid JSON'
    }

    It 'does not load Content when all Content child tasks are excluded' {
        $buildFile = Join-Path $TestDrive 'skip-all-content.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            "    Tasks = @{ Exclude = @('JSON', 'JSONSchema', 'YAML') }"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Not -Contain 'Content'
        $tasks['Validate'].Jobs | Should -Not -Contain '?Content'
    }

    It 'does not load Content children when Content is excluded' {
        $buildFile = Join-Path $TestDrive 'skip-content-parent.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            "    Tasks = @{ Exclude = @('Content') }"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Not -Contain 'Content'
        $tasks.Keys | Should -Not -Contain 'JSON'
        $tasks.Keys | Should -Not -Contain 'JSONSchema'
        $tasks.Keys | Should -Not -Contain 'YAML'
        $tasks['Validate'].Jobs | Should -Not -Contain '?Content'
    }

    It 'validates configured JSON schema mappings' {
        $moduleRoot = Join-Path $TestDrive 'SchemaModule'
        $resourceRoot = Join-Path $moduleRoot 'Resource'
        $schemaRoot = Join-Path $resourceRoot 'Schema'
        New-Item -Path $schemaRoot -ItemType Directory | Out-Null

        Set-Content -Path (Join-Path $resourceRoot 'config.json') -Value '{"name":"plumber"}'
        Set-Content -Path (Join-Path $schemaRoot 'config.schema.json') -Value @'
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

        $buildFile = Join-Path $moduleRoot 'SchemaModule.build.ps1'
        @(
            '$ErrorActionPreference = ''Stop'''
            "Set-Variable -Name BuildRoot -Value '$moduleRoot' -Scope Script"
            'function Add-BuildTask {'
            '    param ('
            '        [string]'
            '        $Name,'
            ''
            '        $Jobs'
            '    )'
            ''
            '    if ($Name -eq "JSONSchema") {'
            '        & $Jobs'
            '    }'
            '}'
            'function Write-Build {'
            '    param ('
            '        $Color,'
            ''
            '        $Message'
            '    )'
            '}'
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            '    Tasks = @{'
            '        JSONSchema = @{'
            '            Schemas = @('
            '                @{'
            "                    Path = 'Resource/**/*.json'"
            "                    Schema = 'Resource/Schema/config.schema.json'"
            '                }'
            '            )'
            "            Exclude = @('Resource/Schema/*.json')"
            '        }'
            '    }'
            '}'
            "'ok'"
        ) | Set-Content -Path $buildFile

        & pwsh -NoLogo -NoProfile -File $buildFile |
            Select-Object -Last 1 |
                Should -Be 'ok'
    }
}
