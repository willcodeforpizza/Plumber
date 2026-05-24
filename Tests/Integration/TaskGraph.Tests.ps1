BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberTaskLoader task graph integration' {
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
            "    Tasks = @{ Local = @('Tasks/ValidateTaskDocs.ps1') }"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'ValidateTaskDocs'
        $tasks.Keys | Should -Contain 'Local'
        $tasks['Local'].Jobs | Should -Contain '?ValidateTaskDocs'
        $tasks['Validate'].Jobs | Should -Contain '?Local'
    }

    It 'rejects removed Local group exclusion config' {
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
            "    Tasks = @{"
            "        Local = @('Tasks/ValidateTaskDocs.ps1')"
            "        Exclude = @('Local')"
            "    }"
            '}'
        ) | Set-Content -Path $buildFile

        { & $script:invokeBuild -Task '??' -File $buildFile } |
            Should -Throw -ExpectedMessage '*Tasks.Exclude is not a known task*'
    }

    It 'registers individual local tasks as skipped by filename task name' {
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
            '    Tasks = @{'
            '        Local = @('
            "        'Tasks/ValidateTaskDocs.ps1'"
            "        'Tasks/CheckGeneratedFiles.ps1'"
            '        )'
            "        ValidateTaskDocs = @{ RunWhen = 'Never' }"
            '    }'
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'ValidateTaskDocs'
        $tasks.Keys | Should -Contain 'CheckGeneratedFiles'
        $tasks.Keys | Should -Contain 'Local'
        $tasks['Local'].Jobs | Should -Contain '?ValidateTaskDocs'
        $tasks['Local'].Jobs | Should -Contain '?CheckGeneratedFiles'
        $tasks['Validate'].Jobs | Should -Contain '?Local'
    }

    It 'keeps Content when JSONSchema remains enabled' {
        $buildFile = Join-Path $TestDrive 'skip-content.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            "    Tasks = @{ JSON = @{ RunWhen = 'Never' }; YAML = @{ RunWhen = 'Never' } }"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'JSON'
        $tasks.Keys | Should -Contain 'YAML'
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

    It 'loads FunctionFiles directly under ModuleConventions' {
        $buildFile = Join-Path $TestDrive 'function-files-loader.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'FunctionFiles'
        $tasks['ModuleConventions'].Jobs | Should -Contain '?FunctionFiles'
    }

    It 'keeps a parent task when at least one child task remains enabled' {
        $buildFile = Join-Path $TestDrive 'partial-code-quality.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            '    Tasks = @{'
            "        PesterUnit = @{ RunWhen = 'Never' }"
            "        PesterIntegration = @{ RunWhen = 'Never' }"
            "        CodeCoverage = @{ RunWhen = 'Never' }"
            '    }'
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'PSScriptAnalyzer'
        $tasks.Keys | Should -Contain 'CodeQuality'
        $tasks.Keys | Should -Not -Contain 'Pester'
        $tasks['CodeQuality'].Jobs | Should -Contain '?PSScriptAnalyzer'
        $tasks['CodeQuality'].Jobs | Should -Contain '?PesterUnit'
        $tasks['CodeQuality'].Jobs | Should -Contain '?PesterIntegration'
        $tasks['CodeQuality'].Jobs | Should -Contain '?CodeCoverage'
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

    It 'runs SetVariables before ChangelogUpdated when invoked directly' {
        $buildFile = Join-Path $TestDrive 'changelog-updated.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = '$PSScriptRoot/../../Plumber.psd1'"
            "    Tasks = @{ ModuleVersion = @{ RunWhen = 'Never' } }"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile

        $tasks['ChangelogUpdated'].Jobs | Should -Contain 'SetVariables'
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

    It 'fails Validate after optional child task errors are collected' {
        $localTaskRoot = Join-Path $TestDrive 'Tasks'
        New-Item -Path $localTaskRoot -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $localTaskRoot 'FailingTask.ps1') -Value @(
            'Add-BuildTask -Name FailingTask -Jobs {'
            "    throw 'expected failure'"
            '}'
        )

        $buildFile = Join-Path $TestDrive 'failing-validate.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = '$PSScriptRoot/../../Plumber.psd1'"
            '    Tasks = @{'
            "        Local = @('Tasks/FailingTask.ps1')"
            '    }'
            '}'
        ) | Set-Content -Path $buildFile

        {
            & $script:invokeBuild -Task Validate -File $buildFile
        } | Should -Throw -ExpectedMessage '*One or more Plumber validation tasks failed*'
    }

    It 'loads Plumber.Release tasks from the repository build file' {
        Import-Module Plumber.Release -RequiredVersion 0.1.4 -ErrorAction Stop

        $tasks = & $script:invokeBuild -Task '??' -File './Plumber.build.ps1'

        $tasks.Keys | Should -Contain 'Release'
        $tasks.Keys | Should -Contain 'BuildModule'
        $tasks.Keys | Should -Contain 'PublishModule'
        $tasks.Keys | Should -Contain 'PublishGitHubRelease'
    }
}
