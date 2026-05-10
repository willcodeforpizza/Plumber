BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Test-PlumberTaskEnabled' {
    It 'returns true when the task is not skipped' {
        InModuleScope Plumber {
            Test-PlumberTaskEnabled -Name JSON -SkipTasks YAML |
                Should -BeTrue
        }
    }

    It 'returns false when the task is skipped' {
        InModuleScope Plumber {
            Test-PlumberTaskEnabled -Name YAML -SkipTasks YAML |
                Should -BeFalse
        }
    }
}

Describe 'Import-PlumberTask' {
    It 'returns task import details when the task is enabled' {
        InModuleScope Plumber {
            $task = Import-PlumberTask -Name JSON -Path 'Content/JSON.ps1' -TaskRoot $TestDrive -Parent Content

            $task.Name | Should -Be 'JSON'
            $task.FullName | Should -Be (Join-Path $TestDrive 'Content/JSON.ps1')
            $task.Parent | Should -Be 'Content'
        }
    }

    It 'returns nothing when the task is skipped' {
        InModuleScope Plumber {
            Import-PlumberTask -Name YAML -Path 'Content/YAML.ps1' -TaskRoot $TestDrive -SkipTasks YAML |
                Should -BeNullOrEmpty
        }
    }
}

Describe 'TaskLoader' {
    BeforeAll {
        $script:invokeBuild = Get-Command Invoke-Build
    }

    It 'keeps Content when JSONSchema remains enabled' {
        $buildFile = Join-Path $TestDrive 'skip-content.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            "    SkipTasks = @('JSON', 'YAML')"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Not -Contain 'JSON'
        $tasks.Keys | Should -Not -Contain 'YAML'
        $tasks.Keys | Should -Contain 'JSONSchema'
        $tasks.Keys | Should -Contain 'Content'
        $tasks['Content'].Jobs | Should -Contain '?JSONSchema'
    }

    It 'loads Help directly under ModuleConventions' {
        $buildFile = Join-Path $TestDrive 'module-conventions.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'Help'
        $tasks['ModuleConventions'].Jobs | Should -Contain '?Help'
    }

    It 'keeps a parent task when at least one child task remains enabled' {
        $buildFile = Join-Path $TestDrive 'partial-code-quality.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            "    SkipTasks = @('PesterUnit', 'PesterIntegration', 'CodeCoverage')"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'PSScriptAnalyzer'
        $tasks.Keys | Should -Contain 'CodeQuality'
        $tasks.Keys | Should -Not -Contain 'Pester'
        $tasks['CodeQuality'].Jobs | Should -Contain '?PSScriptAnalyzer'
        $tasks['CodeQuality'].Jobs | Should -Not -Contain '?PesterUnit'
        $tasks['CodeQuality'].Jobs | Should -Not -Contain '?PesterIntegration'
        $tasks['CodeQuality'].Jobs | Should -Not -Contain '?CodeCoverage'
    }

    It 'loads Pester leaf tasks directly under CodeQuality' {
        $buildFile = Join-Path $TestDrive 'code-quality.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Not -Contain 'Pester'
        $tasks['CodeQuality'].Jobs | Should -Contain '?PesterUnit'
        $tasks['CodeQuality'].Jobs | Should -Contain '?PesterIntegration'
        $tasks['CodeQuality'].Jobs | Should -Contain '?CodeCoverage'
    }

    It 'loads Backticks directly under CodeQuality' {
        $buildFile = Join-Path $TestDrive 'backticks-loader.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'Backticks'
        $tasks['CodeQuality'].Jobs | Should -Contain '?Backticks'
    }

    It 'loads LineLength directly under CodeQuality' {
        $buildFile = Join-Path $TestDrive 'line-length-loader.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'LineLength'
        $tasks['CodeQuality'].Jobs | Should -Contain '?LineLength'
    }

    It 'reports PowerShell line-continuation backticks' {
        $moduleRoot = Join-Path $TestDrive 'BacktickModule'
        $publicRoot = Join-Path $moduleRoot 'Public'
        New-Item -Path $publicRoot -ItemType Directory | Out-Null
        [char] $backtick = 96

        Set-Content -Path (Join-Path $publicRoot 'Invoke-Thing.ps1') -Value @(
            'function Invoke-Thing {'
            "    'hello' $backtick"
            '}'
        )

        $buildFile = Join-Path $moduleRoot 'BacktickModule.build.ps1'
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
            '    if ($Name -eq "Backticks") {'
            '        & $Jobs'
            '    }'
            '}'
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{}'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile 2>&1 |
            Out-String

        $LASTEXITCODE | Should -Not -Be 0
        $result | Should -Match 'Line-continuation backtick found'
    }

    It 'allows PowerShell backticks inside lines' {
        $moduleRoot = Join-Path $TestDrive 'BacktickStringModule'
        $publicRoot = Join-Path $moduleRoot 'Public'
        New-Item -Path $publicRoot -ItemType Directory | Out-Null
        [char] $backtick = 96

        Set-Content -Path (Join-Path $publicRoot 'Invoke-Thing.ps1') -Value @(
            'function Invoke-Thing {'
            "    `"hello$($backtick)nworld`""
            '}'
        )

        $buildFile = Join-Path $moduleRoot 'BacktickStringModule.build.ps1'
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
            '    if ($Name -eq "Backticks") {'
            '        & $Jobs'
            '    }'
            '}'
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{}'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile 2>&1 |
            Out-String

        $LASTEXITCODE | Should -Be 0
        $result | Should -Not -Match 'Line-continuation backtick found'
    }

    It 'reports lines over the configured maximum length' {
        $moduleRoot = Join-Path $TestDrive 'LineLengthModule'
        $publicRoot = Join-Path $moduleRoot 'Public'
        New-Item -Path $publicRoot -ItemType Directory | Out-Null
        $longLine = 'x' * 11

        Set-Content -Path (Join-Path $publicRoot 'Invoke-Thing.ps1') -Value @(
            'function Invoke-Thing {'
            "    '$longLine'"
            '}'
        )

        $buildFile = Join-Path $moduleRoot 'LineLengthModule.build.ps1'
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
            '    if ($Name -eq "LineLength") {'
            '        & $Jobs'
            '    }'
            '}'
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            '    MaxLineLength = 10'
            '}'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile 2>&1 |
            Out-String

        $LASTEXITCODE | Should -Not -Be 0
        $result | Should -Match 'Line is'
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

    It 'does not load Content when all Content child tasks are skipped' {
        $buildFile = Join-Path $TestDrive 'skip-all-content.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            "    SkipTasks = @('JSON', 'JSONSchema', 'YAML')"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Not -Contain 'Content'
        $tasks['Validate'].Jobs | Should -Not -Contain '?Content'
    }

    It 'does not load Content children when Content is skipped' {
        $buildFile = Join-Path $TestDrive 'skip-content-parent.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            "    SkipTasks = @('Content')"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Not -Contain 'Content'
        $tasks.Keys | Should -Not -Contain 'JSON'
        $tasks.Keys | Should -Not -Contain 'JSONSchema'
        $tasks.Keys | Should -Not -Contain 'YAML'
        $tasks['Validate'].Jobs | Should -Not -Contain '?Content'
    }

    It 'sets default coverage and PSSA test inclusion config' {
        $buildFile = Join-Path $TestDrive 'default-config.build.ps1'
        @(
            'function Add-BuildTask {'
            '    param ('
            '        [string]'
            '        $Name,'
            ''
            '        $Jobs'
            '    )'
            '}'
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader)'
            '[pscustomobject]@{'
            '        CoverageMinimum = $script:PlumberConfig.CoverageMinimum'
            '        IncludeTestsInPssa = $script:PlumberConfig.IncludeTestsInPssa'
            '        JsonSchemaCount = $script:PlumberConfig.JsonSchemas.Count'
            '        MaxLineLength = $script:PlumberConfig.MaxLineLength'
            '        PrivateHelpSynopsisOnly = $script:PlumberConfig.PrivateHelpSynopsisOnly'
            '} | ConvertTo-Json -Compress'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile |
            Select-Object -Last 1 |
                ConvertFrom-Json

        $result.CoverageMinimum | Should -Be 75
        $result.IncludeTestsInPssa | Should -BeTrue
        $result.JsonSchemaCount | Should -Be 0
        $result.MaxLineLength | Should -Be 120
        $result.PrivateHelpSynopsisOnly | Should -BeTrue
    }

    It 'sets configured coverage and PSSA test inclusion values' {
        $buildFile = Join-Path $TestDrive 'custom-config.build.ps1'
        @(
            'function Add-BuildTask {'
            '    param ('
            '        [string]'
            '        $Name,'
            ''
            '        $Jobs'
            '    )'
            '}'
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            '    CoverageMinimum = 90'
            '    IncludeTestsInPssa = $false'
            '    MaxLineLength = 100'
            '    PrivateHelpSynopsisOnly = $false'
            '    JsonSchemas = @('
            '        @{'
            "            Path = 'Resource/*.json'"
            "            Schema = 'Resource/Schema/config.schema.json'"
            '        }'
            '    )'
            '}'
            '[pscustomobject]@{'
            '        CoverageMinimum = $script:PlumberConfig.CoverageMinimum'
            '        IncludeTestsInPssa = $script:PlumberConfig.IncludeTestsInPssa'
            '        JsonSchemaCount = $script:PlumberConfig.JsonSchemas.Count'
            '        MaxLineLength = $script:PlumberConfig.MaxLineLength'
            '        PrivateHelpSynopsisOnly = $script:PlumberConfig.PrivateHelpSynopsisOnly'
            '} | ConvertTo-Json -Compress'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile |
            Select-Object -Last 1 |
                ConvertFrom-Json

        $result.CoverageMinimum | Should -Be 90
        $result.IncludeTestsInPssa | Should -BeFalse
        $result.JsonSchemaCount | Should -Be 1
        $result.MaxLineLength | Should -Be 100
        $result.PrivateHelpSynopsisOnly | Should -BeFalse
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
            '    JsonSchemas = @('
            '        @{'
            "            Path = 'Resource/*.json'"
            "            Schema = 'Resource/Schema/config.schema.json'"
            '        }'
            '    )'
            '}'
            "'ok'"
        ) | Set-Content -Path $buildFile

        & pwsh -NoLogo -NoProfile -File $buildFile |
            Select-Object -Last 1 |
                Should -Be 'ok'
    }
}
