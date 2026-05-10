BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Test-PlumberTaskEnabled' {
    It 'returns true when the task is not excluded' {
        InModuleScope Plumber {
            Test-PlumberTaskEnabled -Name JSON -ExcludeTasks YAML |
                Should -BeTrue
        }
    }

    It 'returns false when the task is excluded' {
        InModuleScope Plumber {
            Test-PlumberTaskEnabled -Name YAML -ExcludeTasks YAML |
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

    It 'returns nothing when the task is excluded' {
        InModuleScope Plumber {
            Import-PlumberTask -Name YAML -Path 'Content/YAML.ps1' -TaskRoot $TestDrive -ExcludeTasks YAML |
                Should -BeNullOrEmpty
        }
    }
}

Describe 'TaskLoader' {
    BeforeAll {
        $script:invokeBuild = Get-Command Invoke-Build
    }

    It 'does not load Local when no local tasks are configured' {
        $buildFile = Join-Path $TestDrive 'no-local.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Not -Contain 'Local'
        $tasks['Validate'].Jobs | Should -Not -Contain '?Local'
    }

    It 'loads configured local tasks under Local' {
        $localTaskRoot = Join-Path $TestDrive 'Tasks'
        New-Item -Path $localTaskRoot -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $localTaskRoot 'ValidateTaskDocs.ps1') -Value @(
            'Add-BuildTask -Name ValidateTaskDocs -Jobs {'
            '}'
        )

        $buildFile = Join-Path $TestDrive 'local.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            "    LocalTasks = @('Tasks/ValidateTaskDocs.ps1')"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'ValidateTaskDocs'
        $tasks.Keys | Should -Contain 'Local'
        $tasks['Local'].Jobs | Should -Contain '?ValidateTaskDocs'
        $tasks['Validate'].Jobs | Should -Contain '?Local'
    }

    It 'does not load local tasks when Local is excluded' {
        $localTaskRoot = Join-Path $TestDrive 'Tasks'
        New-Item -Path $localTaskRoot -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $localTaskRoot 'ValidateTaskDocs.ps1') -Value @(
            'Add-BuildTask -Name ValidateTaskDocs -Jobs {'
            '}'
        )

        $buildFile = Join-Path $TestDrive 'exclude-local.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            "    LocalTasks = @('Tasks/ValidateTaskDocs.ps1')"
            "    ExcludeTasks = @('Local')"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Not -Contain 'ValidateTaskDocs'
        $tasks.Keys | Should -Not -Contain 'Local'
        $tasks['Validate'].Jobs | Should -Not -Contain '?Local'
    }

    It 'excludes individual local tasks by filename task name' {
        $localTaskRoot = Join-Path $TestDrive 'Tasks'
        New-Item -Path $localTaskRoot -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $localTaskRoot 'ValidateTaskDocs.ps1') -Value @(
            'Add-BuildTask -Name ValidateTaskDocs -Jobs {'
            '}'
        )
        Set-Content -Path (Join-Path $localTaskRoot 'CheckGeneratedFiles.ps1') -Value @(
            'Add-BuildTask -Name CheckGeneratedFiles -Jobs {'
            '}'
        )

        $buildFile = Join-Path $TestDrive 'exclude-local-task.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            '    LocalTasks = @('
            "        'Tasks/ValidateTaskDocs.ps1'"
            "        'Tasks/CheckGeneratedFiles.ps1'"
            '    )'
            "    ExcludeTasks = @('ValidateTaskDocs')"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Not -Contain 'ValidateTaskDocs'
        $tasks.Keys | Should -Contain 'CheckGeneratedFiles'
        $tasks.Keys | Should -Contain 'Local'
        $tasks['Local'].Jobs | Should -Not -Contain '?ValidateTaskDocs'
        $tasks['Local'].Jobs | Should -Contain '?CheckGeneratedFiles'
        $tasks['Validate'].Jobs | Should -Contain '?Local'
    }

    It 'keeps Content when JSONSchema remains enabled' {
        $buildFile = Join-Path $TestDrive 'skip-content.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            "    ExcludeTasks = @('JSON', 'YAML')"
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
            "    ExcludeTasks = @('PesterUnit', 'PesterIntegration', 'CodeCoverage')"
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

    It 'passes discovered PowerShell files to PSScriptAnalyzer' {
        $moduleRoot = Join-Path $TestDrive 'PssaModule'
        $publicRoot = Join-Path $moduleRoot 'Public'
        $privateRoot = Join-Path $moduleRoot 'Private'
        New-Item -Path $publicRoot, $privateRoot -ItemType Directory | Out-Null

        Set-Content -Path (Join-Path $publicRoot 'Get-Thing.ps1') -Value 'function Get-Thing {}'
        Set-Content -Path (Join-Path $privateRoot 'Helper.psm1') -Value 'function Invoke-Helper {}'
        Set-Content -Path (Join-Path $moduleRoot 'PssaModule.psd1') -Value '@{}'
        Set-Content -Path (Join-Path $moduleRoot 'notes.txt') -Value 'not PowerShell'

        $buildFile = Join-Path $moduleRoot 'PssaModule.build.ps1'
        @(
            '$ErrorActionPreference = ''Stop'''
            "Set-Variable -Name BuildRoot -Value '$moduleRoot' -Scope Script"
            '$script:AnalyzedPaths = @()'
            'function Invoke-ScriptAnalyzer {'
            '    param ('
            '        [string]'
            '        $Path'
            '    )'
            '    $script:AnalyzedPaths += $Path'
            '}'
            'function Add-BuildTask {'
            '    param ('
            '        [string]'
            '        $Name,'
            ''
            '        $Jobs'
            '    )'
            ''
            '    if ($Name -eq "PSScriptAnalyzer") {'
            '        foreach ($job in $Jobs) {'
            '            if ($job -is [scriptblock]) {'
            '                & $job'
            '            }'
            '        }'
            '    }'
            '}'
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ExcludeTasks = @('Backticks', 'LineLength', 'PesterUnit', 'PesterIntegration', 'CodeCoverage')"
            '}'
            '$script:AnalyzedPaths | ForEach-Object { Split-Path $_ -Leaf }'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile

        $result | Should -Contain 'Get-Thing.ps1'
        $result | Should -Contain 'Helper.psm1'
        $result | Should -Contain 'PssaModule.psd1'
        $result | Should -Not -Contain 'notes.txt'
    }

    It 'applies PSScriptAnalyzer path exclusions and test inclusion config' {
        $moduleRoot = Join-Path $TestDrive 'PssaFilterModule'
        $publicRoot = Join-Path $moduleRoot 'Public'
        $privateRoot = Join-Path $moduleRoot 'Private'
        $testRoot = Join-Path $moduleRoot 'Tests'
        $testAssetRoot = Join-Path $moduleRoot 'TestsAsset'
        New-Item -Path $publicRoot, $privateRoot, $testRoot, $testAssetRoot -ItemType Directory |
            Out-Null

        Set-Content -Path (Join-Path $publicRoot 'Get-Thing.ps1') -Value 'function Get-Thing {}'
        Set-Content -Path (Join-Path $privateRoot 'Skip-Thing.ps1') -Value 'function Skip-Thing {}'
        Set-Content -Path (Join-Path $testRoot 'Get-Thing.Tests.ps1') -Value 'Describe thing {}'
        Set-Content -Path (Join-Path $testAssetRoot 'Keep-Thing.ps1') -Value 'function Keep-Thing {}'

        $buildFile = Join-Path $moduleRoot 'PssaFilterModule.build.ps1'
        @(
            '$ErrorActionPreference = ''Stop'''
            "Set-Variable -Name BuildRoot -Value '$moduleRoot' -Scope Script"
            '$script:AnalyzedPaths = @()'
            'function Invoke-ScriptAnalyzer {'
            '    param ('
            '        [string]'
            '        $Path'
            '    )'
            '    $script:AnalyzedPaths += $Path'
            '}'
            'function Add-BuildTask {'
            '    param ('
            '        [string]'
            '        $Name,'
            ''
            '        $Jobs'
            '    )'
            ''
            '    if ($Name -eq "PSScriptAnalyzer") {'
            '        foreach ($job in $Jobs) {'
            '            if ($job -is [scriptblock]) {'
            '                & $job'
            '            }'
            '        }'
            '    }'
            '}'
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            '    IncludeTestsInPssa = $false'
            '    ExcludePaths = @{'
            "        PSScriptAnalyzer = @('Private/*')"
            '    }'
            "    ExcludeTasks = @('Backticks', 'LineLength', 'PesterUnit', 'PesterIntegration', 'CodeCoverage')"
            '}'
            '$script:AnalyzedPaths | ForEach-Object { Split-Path $_ -Leaf }'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile

        $result | Should -Contain 'Get-Thing.ps1'
        $result | Should -Contain 'Keep-Thing.ps1'
        $result | Should -Not -Contain 'Skip-Thing.ps1'
        $result | Should -Not -Contain 'Get-Thing.Tests.ps1'
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

    It 'excludes configured paths from Backticks validation' {
        $moduleRoot = Join-Path $TestDrive 'BacktickExcludeModule'
        $assetRoot = Join-Path $moduleRoot 'Tests/Assets'
        New-Item -Path $assetRoot -ItemType Directory | Out-Null
        [char] $backtick = 96

        Set-Content -Path (Join-Path $assetRoot 'Fixture.ps1') -Value @(
            'function Invoke-Fixture {'
            "    'hello' $backtick"
            '}'
        )

        $buildFile = Join-Path $moduleRoot 'BacktickExcludeModule.build.ps1'
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
            '. (Get-PlumberTaskLoader) -Config @{'
            '    ExcludePaths = @{'
            "        Backticks = @('Tests/Assets/*')"
            '    }'
            '}'
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

    It 'reports TODO comments' {
        $moduleRoot = Join-Path $TestDrive 'ToDoModule'
        $publicRoot = Join-Path $moduleRoot 'Public'
        New-Item -Path $publicRoot -ItemType Directory | Out-Null

        Set-Content -Path (Join-Path $publicRoot 'Invoke-Thing.ps1') -Value @(
            'function Invoke-Thing {'
            '    # TODO: fix this'
            '}'
        )

        $buildFile = Join-Path $moduleRoot 'ToDoModule.build.ps1'
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
            '    if ($Name -eq "ToDo") {'
            '        & $Jobs'
            '    }'
            '}'
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{}'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile 2>&1 |
            Out-String

        $LASTEXITCODE | Should -Not -Be 0
        $result | Should -Match 'Invoke-Thing.ps1: fix this'
    }

    It 'ignores TODO markers inside strings' {
        $moduleRoot = Join-Path $TestDrive 'ToDoStringModule'
        $publicRoot = Join-Path $moduleRoot 'Public'
        New-Item -Path $publicRoot -ItemType Directory | Out-Null

        Set-Content -Path (Join-Path $publicRoot 'Invoke-Thing.ps1') -Value @(
            'function Invoke-Thing {'
            '    "This text mentions #TODO: without creating a TODO comment"'
            '}'
        )

        $buildFile = Join-Path $moduleRoot 'ToDoStringModule.build.ps1'
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
            '    if ($Name -eq "ToDo") {'
            '        & $Jobs'
            '    }'
            '}'
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{}'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile 2>&1 |
            Out-String

        $LASTEXITCODE | Should -Be 0
        $result | Should -Not -Match 'mentions'
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
            "    ExcludeTasks = @('JSON', 'JSONSchema', 'YAML')"
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
            "    ExcludeTasks = @('Content')"
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
            '        DiffBase = $script:PlumberConfig.DiffBase'
            '        FileScope = $script:PlumberConfig.FileScope'
            '        IncludeTestsInPssa = $script:PlumberConfig.IncludeTestsInPssa'
            '        ExcludePathCount = $script:PlumberConfig.ExcludePaths.Count'
            '        JsonSchemaCount = $script:PlumberConfig.JsonSchemas.Count'
            '        MaxLineLength = $script:PlumberConfig.MaxLineLength'
            '        PrivateHelpSynopsisOnly = $script:PlumberConfig.PrivateHelpSynopsisOnly'
            '} | ConvertTo-Json -Compress'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile |
            Select-Object -Last 1 |
                ConvertFrom-Json

        $result.CoverageMinimum | Should -Be 75
        $result.DiffBase | Should -BeNullOrEmpty
        $result.FileScope | Should -Be 'All'
        $result.IncludeTestsInPssa | Should -BeTrue
        $result.ExcludePathCount | Should -Be 0
        $result.JsonSchemaCount | Should -Be 0
        $result.MaxLineLength | Should -Be 115
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
            '    ExcludePaths = @{'
            "        Backticks = @('Tests/Assets/*')"
            '    }'
            "    DiffBase = 'origin/main'"
            "    FileScope = 'Changed'"
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
            '        BackticksExcludePath = $script:PlumberConfig.ExcludePaths.Backticks[0]'
            '        DiffBase = $script:PlumberConfig.DiffBase'
            '        FileScope = $script:PlumberConfig.FileScope'
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
        $result.BackticksExcludePath | Should -Be 'Tests/Assets/*'
        $result.DiffBase | Should -Be 'origin/main'
        $result.FileScope | Should -Be 'Changed'
        $result.IncludeTestsInPssa | Should -BeFalse
        $result.JsonSchemaCount | Should -Be 1
        $result.MaxLineLength | Should -Be 100
        $result.PrivateHelpSynopsisOnly | Should -BeFalse
    }

    It 'tests task-scoped path exclusions' {
        $moduleRoot = Join-Path $TestDrive 'ExcludeModule'
        $assetRoot = Join-Path $moduleRoot 'Tests/Assets'
        New-Item -Path $assetRoot -ItemType Directory | Out-Null
        $excludedFile = Join-Path $assetRoot 'Fixture.ps1'
        Set-Content -Path $excludedFile -Value '$value = 1'
        $includedFile = Join-Path $moduleRoot 'Public.ps1'
        Set-Content -Path $includedFile -Value '$value = 1'

        $buildFile = Join-Path $moduleRoot 'ExcludeModule.build.ps1'
        @(
            "Set-Variable -Name BuildRoot -Value '$moduleRoot' -Scope Script"
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
            '    ExcludePaths = @{'
            "        Backticks = @('Tests/Assets/*')"
            '    }'
            '}'
            '[pscustomobject]@{'
            (
                '    ExcludedForBackticks = ' +
                'Test-PlumberTaskPathExcluded -Task Backticks -Path ''' +
                $excludedFile +
                ''''
            )
            (
                '    ExcludedForPssa = ' +
                'Test-PlumberTaskPathExcluded -Task PSScriptAnalyzer -Path ''' +
                $excludedFile +
                ''''
            )
            (
                '    IncludedForBackticks = ' +
                'Test-PlumberTaskPathExcluded -Task Backticks -Path ''' +
                $includedFile +
                ''''
            )
            '} | ConvertTo-Json -Compress'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile |
            Select-Object -Last 1 |
                ConvertFrom-Json

        $result.ExcludedForBackticks | Should -BeTrue
        $result.ExcludedForPssa | Should -BeFalse
        $result.IncludedForBackticks | Should -BeFalse
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
            "            Path = 'Resource/**/*.json'"
            "            Schema = 'Resource/Schema/config.schema.json'"
            '        }'
            '    )'
            '    ExcludePaths = @{'
            "        JSONSchema = @('Resource/Schema/*.json')"
            '    }'
            '}'
            "'ok'"
        ) | Set-Content -Path $buildFile

        & pwsh -NoLogo -NoProfile -File $buildFile |
            Select-Object -Last 1 |
                Should -Be 'ok'
    }
}
