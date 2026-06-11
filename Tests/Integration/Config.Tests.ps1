BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberTaskLoader config integration' {
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
            '        CoverageMinimum = $script:PlumberConfig.Tasks.CodeCoverage.Minimum'
            '        DiffBase = $script:PlumberConfig.DiffBase'
            '        FileScope = $script:PlumberConfig.FileScope'
            '        IncludeTestsInPssa = $script:PlumberConfig.Tasks.PSScriptAnalyzer.IncludeTests'
            '        BackticksExcludePathCount = $script:PlumberConfig.Tasks.Backticks.Exclude.Count'
            '        JsonSchemaCount = $script:PlumberConfig.Tasks.JSONSchema.Schemas.Count'
            '        MaxLineLength = $script:PlumberConfig.Tasks.LineLength.MaxLength'
            '        PrivateHelpSynopsisOnly = $script:PlumberConfig.Tasks.Help.PrivateSynopsisOnly'
            '} | ConvertTo-Json -Compress'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile |
            Select-Object -Last 1 |
                ConvertFrom-Json

        $result.CoverageMinimum | Should -Be 75
        $result.DiffBase | Should -BeNullOrEmpty
        $result.FileScope | Should -Be 'All'
        $result.IncludeTestsInPssa | Should -BeTrue
        $result.BackticksExcludePathCount | Should -Be 0
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
            "    DiffBase = 'origin/main'"
            "    FileScope = 'Changed'"
            '    Tasks = @{'
            '        Backticks = @{'
            "            Exclude = @('Tests/Assets/*')"
            '        }'
            '        CodeCoverage = @{'
            '            Minimum = 90'
            '        }'
            '        Help = @{'
            '            PrivateSynopsisOnly = $false'
            '        }'
            '        JSONSchema = @{'
            '            Schemas = @('
            '                @{'
            "                    Path = 'Resource/*.json'"
            "                    Schema = 'Resource/Schema/config.schema.json'"
            '                }'
            '            )'
            '        }'
            '        LineLength = @{'
            '            MaxLength = 100'
            '        }'
            '        PSScriptAnalyzer = @{'
            '            IncludeTests = $false'
            '        }'
            '    }'
            '}'
            '[pscustomobject]@{'
            '        CoverageMinimum = $script:PlumberConfig.Tasks.CodeCoverage.Minimum'
            '        BackticksExcludePath = $script:PlumberConfig.Tasks.Backticks.Exclude[0]'
            '        DiffBase = $script:PlumberConfig.DiffBase'
            '        FileScope = $script:PlumberConfig.FileScope'
            '        IncludeTestsInPssa = $script:PlumberConfig.Tasks.PSScriptAnalyzer.IncludeTests'
            '        JsonSchemaCount = $script:PlumberConfig.Tasks.JSONSchema.Schemas.Count'
            '        MaxLineLength = $script:PlumberConfig.Tasks.LineLength.MaxLength'
            '        PrivateHelpSynopsisOnly = $script:PlumberConfig.Tasks.Help.PrivateSynopsisOnly'
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

    It 'adds configured module folders to source-root tasks' {
        $moduleRoot = Join-Path $TestDrive 'SourceRootModule'
        New-Item -Path (Join-Path $moduleRoot 'Public') -ItemType Directory | Out-Null
        New-Item -Path (Join-Path $moduleRoot 'Private') -ItemType Directory | Out-Null
        New-Item -Path (Join-Path $moduleRoot 'TaskFunctions') -ItemType Directory | Out-Null
        '@{ ModuleVersion = "0.0.1" }' | Set-Content -Path (
            Join-Path $moduleRoot 'SourceRootModule.psd1'
        )

        $buildFile = Join-Path $moduleRoot 'source-roots.build.ps1'
        @(
            'function Add-BuildTask {'
            '    param ('
            '        [string]'
            '        $Name,'
            ''
            '        $Jobs'
            '    )'
            ''
            '    if ($Name -eq "SetVariables") {'
            '        & $Jobs'
            '    }'
            '}'
            'function Write-Build {'
            '    param ($Color, $Message)'
            '    $null = $Color'
            '    $null = $Message'
            '}'
            "Set-Variable -Name BuildRoot -Value '$moduleRoot' -Scope Script"
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'SourceRootModule.psd1'"
            "    IncludeModuleFolders = @('TaskFunctions')"
            '}'
            '$script:moduleFolders | ForEach-Object { Split-Path $_ -Leaf }'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile

        $result | Should -Contain 'Public'
        $result | Should -Contain 'Private'
        $result | Should -Contain 'TaskFunctions'
    }


    It 'selects the manifest matching the build root name when dependency manifests exist' {
        $moduleRoot = Join-Path $TestDrive 'DeterministicModule'
        New-Item -Path $moduleRoot -ItemType Directory | Out-Null
        '@{ ModuleVersion = "0.0.1" }' | Set-Content -Path (
            Join-Path $moduleRoot 'DeterministicModule.dependencies.psd1'
        )
        '@{ ModuleVersion = "0.0.1" }' | Set-Content -Path (
            Join-Path $moduleRoot 'DeterministicModule.psd1'
        )

        $buildFile = Join-Path $moduleRoot 'deterministic-manifest.build.ps1'
        @(
            'function Add-BuildTask {'
            '    param ('
            '        [string]'
            '        $Name,'
            ''
            '        $Jobs'
            '    )'
            ''
            '    if ($Name -eq "SetVariables") {'
            '        & $Jobs'
            '    }'
            '}'
            'function Write-Build {'
            '    param ($Color, $Message)'
            '    $null = $Color'
            '    $null = $Message'
            '}'
            "Set-Variable -Name BuildRoot -Value '$moduleRoot' -Scope Script"
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader)'
            '$script:moduleManifest.Name'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile

        $result | Select-Object -Last 1 | Should -Be 'DeterministicModule.psd1'
    }

    It 'fails with a friendly message when manifest discovery is ambiguous' {
        $moduleRoot = Join-Path $TestDrive 'AmbiguousModule'
        New-Item -Path $moduleRoot -ItemType Directory | Out-Null
        '@{ ModuleVersion = "0.0.1" }' | Set-Content -Path (Join-Path $moduleRoot 'Alpha.psd1')
        '@{ ModuleVersion = "0.0.1" }' | Set-Content -Path (Join-Path $moduleRoot 'Beta.psd1')

        $buildFile = Join-Path $moduleRoot 'ambiguous-manifest.build.ps1'
        @(
            'function Add-BuildTask {'
            '    param ('
            '        [string]'
            '        $Name,'
            ''
            '        $Jobs'
            '    )'
            ''
            '    if ($Name -eq "SetVariables") {'
            '        & $Jobs'
            '    }'
            '}'
            'function Write-Build {'
            '    param ($Color, $Message)'
            '    $null = $Color'
            '    $null = $Message'
            '}'
            "Set-Variable -Name BuildRoot -Value '$moduleRoot' -Scope Script"
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            'try {'
            '    . (Get-PlumberTaskLoader)'
            '    exit 0'
            '} catch {'
            '    $_.Exception.Message'
            '    exit 1'
            '}'
        ) | Set-Content -Path $buildFile

        $output = & pwsh -NoLogo -NoProfile -File $buildFile 2>&1

        $LASTEXITCODE | Should -Not -Be 0
        $output -join "`n" | Should -Match 'ModuleManifest is not configured'
        $output -join "`n" | Should -Match 'Alpha\.psd1'
        $output -join "`n" | Should -Match 'Beta\.psd1'
    }

    It 'fails at task-loader time for invalid config with a friendly message' {
        $buildFile = Join-Path $TestDrive 'invalid-config.build.ps1'
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
            'try {'
            '    . (Get-PlumberTaskLoader) -Config @{'
            '    Tasks = @{'
            '        PSScriptAnalyzer = @{'
            "            Excdddlude = @('Tests/*')"
            '        }'
            '    }'
            '    }'
            '    exit 0'
            '} catch {'
            '    $_.Exception.Message'
            '    exit 1'
            '}'
        ) | Set-Content -Path $buildFile

        $output = & pwsh -NoLogo -NoProfile -File $buildFile 2>&1

        $LASTEXITCODE | Should -Not -Be 0
        $output -join "`n" |
            Should -Match 'Tasks\.PSScriptAnalyzer\.Excdddlude is[\s|]+not a known setting'
        $output -join "`n" | Should -Match 'Did you mean Exclude'
    }
}
