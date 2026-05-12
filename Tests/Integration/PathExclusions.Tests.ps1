BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Test-PlumberTaskPathExcluded integration' {
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
}
