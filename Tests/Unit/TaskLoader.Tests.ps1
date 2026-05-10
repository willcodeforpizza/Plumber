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

    It 'does not load Content when all Content child tasks are skipped' {
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
        $tasks.Keys | Should -Not -Contain 'Content'
        $tasks['Validate'].Jobs | Should -Not -Contain '?Content'
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
            '} | ConvertTo-Json -Compress'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile |
            Select-Object -Last 1 |
                ConvertFrom-Json

        $result.CoverageMinimum | Should -Be 75
        $result.IncludeTestsInPssa | Should -BeTrue
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
            '}'
            '[pscustomobject]@{'
            '        CoverageMinimum = $script:PlumberConfig.CoverageMinimum'
            '        IncludeTestsInPssa = $script:PlumberConfig.IncludeTestsInPssa'
            '} | ConvertTo-Json -Compress'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile |
            Select-Object -Last 1 |
                ConvertFrom-Json

        $result.CoverageMinimum | Should -Be 90
        $result.IncludeTestsInPssa | Should -BeFalse
    }
}
