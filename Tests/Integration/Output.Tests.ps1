BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-Plumber output integration' {
    It 'reports PSScriptAnalyzer details without duplicate group failures' {
        $moduleRoot = Join-Path $TestDrive 'AnalyzerOutputModule'
        $publicRoot = Join-Path $moduleRoot 'Public'
        New-Item -Path $publicRoot -ItemType Directory | Out-Null

        Set-Content -Path (Join-Path $publicRoot 'Get-Bad.ps1') -Value @(
            'function Get-Bad {'
            '    Write-Host "bad output"'
            '}'
        )
        Set-Content -Path (Join-Path $moduleRoot 'AnalyzerOutputModule.psd1') -Value @(
            '@{'
            "    ModuleVersion = '0.1.0'"
            '}'
        )

        $buildFile = Join-Path $moduleRoot 'AnalyzerOutputModule.build.ps1'
        @(
            '. (Get-PlumberTaskLoader) -Config @{'
            '    Tasks = @{'
            '        Exclude = @('
            "            'Backticks',"
            "            'LineLength',"
            "            'PesterUnit',"
            "            'PesterIntegration',"
            "            'CodeCoverage',"
            "            'ReleaseHygiene',"
            "            'Content',"
            "            'ModuleConventions'"
            '        )'
            '    }'
            '}'
        ) | Set-Content -Path $buildFile

        Push-Location $moduleRoot
        try {
            $summary = try {
                Invoke-Plumber -OutputMode Summary -NoFormat
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }

            $summaryText = $summary | Out-String
            $summaryText | Should -Match 'PSScriptAnalyzer:'
            $summaryText | Should -Match 'PSAvoidUsingWriteHost'
            $summaryText | Should -Not -Match 'CodeQuality:'
            $summaryText | Should -Not -Match 'Validate:'

            $table = try {
                Invoke-Plumber -OutputMode Table -NoFormat
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }

            $tableText = $table | Out-String
            $tableText | Should -Match 'PSScriptAnalyzer\s+Failed'
            $tableText | Should -Match 'PSAvoidUsingWriteHost'
            $tableText | Should -Not -Match 'CodeQuality\s+Failed'
            $tableText | Should -Not -Match 'Validate\s+Failed'

            $jsonText = try {
                Invoke-Plumber -OutputMode Json
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }
            $json = $jsonText | ConvertFrom-Json

            $json.Tasks.Name | Should -Contain 'PSScriptAnalyzer'
            $json.Tasks.Name | Should -Not -Contain 'CodeQuality'
            $json.Tasks.Name | Should -Not -Contain 'Validate'
            $json.Failures[0].Name | Should -Be 'PSScriptAnalyzer'
            $json.Failures[0].Error | Should -Match 'PSAvoidUsingWriteHost'
        } finally {
            Pop-Location
        }
    }

    It 'reports failing Pester results in table mode without raw output' {
        $moduleRoot = Join-Path $TestDrive 'PesterOutputModule'
        $unitRoot = Join-Path $moduleRoot 'Tests/Unit'
        New-Item -Path $unitRoot -ItemType Directory -Force | Out-Null

        Set-Content -Path (Join-Path $moduleRoot 'PesterOutputModule.psd1') -Value @(
            '@{'
            "    RootModule = 'PesterOutputModule.psm1'"
            "    ModuleVersion = '0.1.0'"
            "    GUID = '11111111-1111-1111-1111-111111111111'"
            '    FunctionsToExport = @()'
            '}'
        )
        Set-Content -Path (Join-Path $moduleRoot 'PesterOutputModule.psm1') -Value ''
        Set-Content -Path (Join-Path $unitRoot 'Throw.Tests.ps1') -Value @(
            "Describe 'Pester failure output' {"
            "    It 'throws' {"
            "        throw 'intentional pester failure'"
            '    }'
            '}'
        )

        $buildFile = Join-Path $moduleRoot 'PesterOutputModule.build.ps1'
        @(
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'PesterOutputModule.psd1'"
            '    Tasks = @{'
            '        Exclude = @('
            "            'PSScriptAnalyzer',"
            "            'Backticks',"
            "            'LineLength',"
            "            'PesterIntegration',"
            "            'CodeCoverage',"
            "            'ReleaseHygiene',"
            "            'Content',"
            "            'ModuleConventions'"
            '        )'
            '    }'
            '}'
        ) | Set-Content -Path $buildFile

        Push-Location $moduleRoot
        try {
            $raw = try {
                Invoke-Plumber -Task PesterUnit -OutputMode Raw -NoFormat
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }
            $rawText = $raw | Out-String
            $rawText | Should -Match 'PesterUnit\s+Failed'

            $table = try {
                Invoke-Plumber -Task PesterUnit -OutputMode Table -NoFormat
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }
            $tableText = $table | Out-String
            $tableText | Should -Match 'PesterUnit\s+Failed'
            $tableText | Should -Match 'Pester failed with 1 error\(s\)'
        } finally {
            Pop-Location
        }
    }
}
