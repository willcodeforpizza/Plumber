BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberBackticks' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'BacktickModule'
        $script:publicRoot = Join-Path $script:buildRoot 'Public'
        New-Item -Path $script:publicRoot -ItemType Directory -Force | Out-Null
        [char] $script:backtick = 96
    }

    It 'reports PowerShell line-continuation backticks' {
        Set-Content -Path (Join-Path $script:publicRoot 'Invoke-Thing.ps1') -Value @(
            'function Invoke-Thing {'
            "    'hello' $script:backtick"
            '}'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    Backticks = @{
                        Exclude = @()
                    }
                }
            }

            { Invoke-PlumberBackticks -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Invoke-Thing.ps1:2 - Line-continuation backtick found*'
        }
    }

    It 'allows PowerShell backticks inside lines' {
        Set-Content -Path (Join-Path $script:publicRoot 'Invoke-Thing.ps1') -Value @(
            'function Invoke-Thing {'
            "    `"hello$($script:backtick)nworld`""
            '}'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    Backticks = @{
                        Exclude = @()
                    }
                }
            }

            { Invoke-PlumberBackticks -ErrorAction Stop } | Should -Not -Throw
        }
    }

    It 'excludes configured paths from Backticks validation' {
        $assetRoot = Join-Path $script:buildRoot 'Tests/Assets'
        New-Item -Path $assetRoot -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $assetRoot 'Fixture.ps1') -Value @(
            'function Invoke-Fixture {'
            "    'hello' $script:backtick"
            '}'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    Backticks = @{
                        Exclude = @('Tests/Assets/*')
                    }
                }
            }

            { Invoke-PlumberBackticks -ErrorAction Stop } | Should -Not -Throw
        }
    }
}
