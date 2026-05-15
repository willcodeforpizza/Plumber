BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberTaskLoader code-quality integration' {
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
            '    Tasks = @{'
            "        Exclude = @('Backticks', 'LineLength', 'PesterUnit', 'PesterIntegration', 'CodeCoverage')"
            '    }'
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
            '    Tasks = @{'
            '        PSScriptAnalyzer = @{'
            '            IncludeTests = $false'
            "            Exclude = @('Private/*')"
            '        }'
            "        Exclude = @('Backticks', 'LineLength', 'PesterUnit', 'PesterIntegration', 'CodeCoverage')"
            '    }'
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
            '    Tasks = @{'
            '        Backticks = @{'
            "            Exclude = @('Tests/Assets/*')"
            '        }'
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
            '    Tasks = @{'
            '        LineLength = @{'
            '            MaxLength = 10'
            '        }'
            '    }'
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
}
