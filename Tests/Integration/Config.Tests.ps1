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
}
