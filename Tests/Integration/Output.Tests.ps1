BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-Plumber output integration' {
    It 'emits parseable JSON to stdout and diagnostics to stderr on command-line failure' {
        $moduleRoot = Join-Path $TestDrive 'JsonContractFailureModule'
        New-Item -Path $moduleRoot -ItemType Directory | Out-Null
        Set-Content -Path (Join-Path $moduleRoot 'JsonContractFailureModule.psd1') -Value @(
            '@{'
            "    ModuleVersion = '0.1.0'"
            '}'
        )
        Set-Content -Path (Join-Path $moduleRoot 'JsonContractFailureModule.psm1') -Value '# TODO: make this fail'

        $buildFile = Join-Path $moduleRoot 'JsonContractFailureModule.build.ps1'
        Set-Content -Path $buildFile -Value @(
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'JsonContractFailureModule.psd1'"
            '}'
        )

        $stdoutPath = Join-Path $TestDrive 'plumber.stdout.json'
        $stderrPath = Join-Path $TestDrive 'plumber.stderr.txt'
        $modulePath = (Resolve-Path "$PSScriptRoot/../../Plumber.psd1").Path.Replace("'", "''")
        $moduleRootLiteral = $moduleRoot.Replace("'", "''")
        $command = @"
Import-Module '$modulePath' -Force
Push-Location '$moduleRootLiteral'
Invoke-Plumber -Task ToDo -OutputMode Json -NoFormat
"@

        & (Get-Command pwsh).Source -NoLogo -NoProfile -Command $command 1> $stdoutPath 2> $stderrPath
        $exitCode = $LASTEXITCODE

        $exitCode | Should -Not -Be 0
        $stdout = Get-Content -Path $stdoutPath -Raw
        $stderr = Get-Content -Path $stderrPath -Raw

        { $stdout | ConvertFrom-Json } | Should -Not -Throw
        $json = $stdout | ConvertFrom-Json
        $json.Success | Should -BeFalse
        $json.Failed | Should -Be 1
        $json.Tasks[0].Name | Should -Be 'ToDo'
        $json.Tasks[0].Status | Should -Be 'Failed'
        $json.Failures[0].Error | Should -Match 'make this fail'
        $stdout | Should -Not -Match 'Build failed!'
        $stderr | Should -Match 'Build failed!'
    }

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
            "        Backticks = @{ RunWhen = 'Never' }"
            "        LineLength = @{ RunWhen = 'Never' }"
            "        PesterUnit = @{ RunWhen = 'Never' }"
            "        PesterIntegration = @{ RunWhen = 'Never' }"
            "        CodeCoverage = @{ RunWhen = 'Never' }"
            "        ModuleVersion = @{ RunWhen = 'Never' }"
            "        ChangelogUpdated = @{ RunWhen = 'Never' }"
            "        JSON = @{ RunWhen = 'Never' }"
            "        JSONSchema = @{ RunWhen = 'Never' }"
            "        YAML = @{ RunWhen = 'Never' }"
            "        Manifest = @{ RunWhen = 'Never' }"
            "        PublicFunctions = @{ RunWhen = 'Never' }"
            "        PublicFunctionPrefix = @{ RunWhen = 'Never' }"
            "        FunctionFiles = @{ RunWhen = 'Never' }"
            "        Naming = @{ RunWhen = 'Never' }"
            "        ToDo = @{ RunWhen = 'Never' }"
            "        Help = @{ RunWhen = 'Never' }"
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
            "        PSScriptAnalyzer = @{ RunWhen = 'Never' }"
            "        Backticks = @{ RunWhen = 'Never' }"
            "        LineLength = @{ RunWhen = 'Never' }"
            "        PesterIntegration = @{ RunWhen = 'Never' }"
            "        CodeCoverage = @{ RunWhen = 'Never' }"
            "        ModuleVersion = @{ RunWhen = 'Never' }"
            "        ChangelogUpdated = @{ RunWhen = 'Never' }"
            "        JSON = @{ RunWhen = 'Never' }"
            "        JSONSchema = @{ RunWhen = 'Never' }"
            "        YAML = @{ RunWhen = 'Never' }"
            "        Manifest = @{ RunWhen = 'Never' }"
            "        PublicFunctions = @{ RunWhen = 'Never' }"
            "        PublicFunctionPrefix = @{ RunWhen = 'Never' }"
            "        FunctionFiles = @{ RunWhen = 'Never' }"
            "        Naming = @{ RunWhen = 'Never' }"
            "        ToDo = @{ RunWhen = 'Never' }"
            "        Help = @{ RunWhen = 'Never' }"
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
