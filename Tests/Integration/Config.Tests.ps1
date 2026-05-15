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
}
