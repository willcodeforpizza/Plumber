BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberPSScriptAnalyzer' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'PssaModule'
        $script:publicRoot = Join-Path $script:buildRoot 'Public'
        $script:privateRoot = Join-Path $script:buildRoot 'Private'
        New-Item -Path $script:publicRoot, $script:privateRoot -ItemType Directory -Force |
            Out-Null
    }

    It 'passes discovered PowerShell files to PSScriptAnalyzer' {
        Set-Content -Path (Join-Path $script:publicRoot 'Get-Thing.ps1') -Value 'function Get-Thing {}'
        Set-Content -Path (Join-Path $script:privateRoot 'Helper.psm1') -Value 'function Invoke-Helper {}'
        Set-Content -Path (Join-Path $script:buildRoot 'PssaModule.psd1') -Value '@{}'
        Set-Content -Path (Join-Path $script:buildRoot 'notes.txt') -Value 'not PowerShell'

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            Mock Invoke-ScriptAnalyzer {}

            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    PSScriptAnalyzer = @{
                        Exclude      = @()
                        IncludeTests = $true
                    }
                }
            }

            Invoke-PlumberPSScriptAnalyzer

            Should -Invoke Invoke-ScriptAnalyzer -ParameterFilter {
                (Split-Path $Path -Leaf) -eq 'Get-Thing.ps1'
            }
            Should -Invoke Invoke-ScriptAnalyzer -ParameterFilter {
                (Split-Path $Path -Leaf) -eq 'Helper.psm1'
            }
            Should -Invoke Invoke-ScriptAnalyzer -ParameterFilter {
                (Split-Path $Path -Leaf) -eq 'PssaModule.psd1'
            }
            Should -Not -Invoke Invoke-ScriptAnalyzer -ParameterFilter {
                (Split-Path $Path -Leaf) -eq 'notes.txt'
            }
        }
    }

    It 'applies PSScriptAnalyzer path exclusions and test inclusion config' {
        $testRoot = Join-Path $script:buildRoot 'Tests'
        $caseVariantTestRoot = Join-Path $script:buildRoot 'tests'
        $testAssetRoot = Join-Path $script:buildRoot 'TestsAsset'
        New-Item -Path $testRoot, $caseVariantTestRoot, $testAssetRoot -ItemType Directory -Force |
            Out-Null
        Set-Content -Path (Join-Path $script:publicRoot 'Get-Thing.ps1') -Value 'function Get-Thing {}'
        Set-Content -Path (Join-Path $script:privateRoot 'Skip-Thing.ps1') -Value 'function Skip-Thing {}'
        Set-Content -Path (Join-Path $testRoot 'Get-Thing.Tests.ps1') -Value 'Describe thing {}'
        Set-Content -Path (Join-Path $caseVariantTestRoot 'Keep-LowercaseTests.ps1') -Value @(
            'function Keep-LowercaseTests {}'
        )
        Set-Content -Path (Join-Path $testAssetRoot 'Keep-Thing.ps1') -Value 'function Keep-Thing {}'

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            Mock Invoke-ScriptAnalyzer {}

            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    PSScriptAnalyzer = @{
                        Exclude      = @('Private/*')
                        IncludeTests = $false
                    }
                }
            }

            Invoke-PlumberPSScriptAnalyzer

            Should -Invoke Invoke-ScriptAnalyzer -ParameterFilter {
                (Split-Path $Path -Leaf) -eq 'Get-Thing.ps1'
            }
            Should -Invoke Invoke-ScriptAnalyzer -ParameterFilter {
                (Split-Path $Path -Leaf) -eq 'Keep-Thing.ps1'
            }
            Should -Not -Invoke Invoke-ScriptAnalyzer -ParameterFilter {
                (Split-Path $Path -Leaf) -eq 'Skip-Thing.ps1'
            }
            Should -Not -Invoke Invoke-ScriptAnalyzer -ParameterFilter {
                (Split-Path $Path -Leaf) -eq 'Get-Thing.Tests.ps1'
            }
            if ($IsLinux) {
                Should -Invoke Invoke-ScriptAnalyzer -ParameterFilter {
                    (Split-Path $Path -Leaf) -eq 'Keep-LowercaseTests.ps1'
                }
            } else {
                Should -Not -Invoke Invoke-ScriptAnalyzer -ParameterFilter {
                    (Split-Path $Path -Leaf) -eq 'Keep-LowercaseTests.ps1'
                }
            }
        }
    }
}
