BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberPesterUnit' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'PesterUnitModule'
        Remove-Item -Path $script:buildRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $script:buildRoot -ItemType Directory -Force | Out-Null
    }

    It 'reports when no unit tests are found' {
        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            function Write-Build {
                param ($Color, $Message)
                $null = $Color
                $null = $Message
            }
            Mock Write-Build {}
            Mock Invoke-PlumberPester {}

            Invoke-PlumberPesterUnit

            Should -Invoke Write-Build -ParameterFilter {
                $Color -eq 'Yellow' -and $Message -eq 'No unit tests found'
            }
            Should -Not -Invoke Invoke-PlumberPester
        }
    }

    It 'runs unit tests with the resolved manifest, coverage paths and stream output config' {
        $unitTestPath = Join-Path $script:buildRoot 'Tests/Unit'
        New-Item -Path $unitTestPath -ItemType Directory -Force | Out-Null
        $manifestPath = Join-Path $script:buildRoot 'src/PesterUnitModule.psd1'
        New-Item -Path (Join-Path $script:buildRoot 'src') -ItemType Directory -Force | Out-Null
        Set-Content -Path $manifestPath -Value "@{ModuleVersion = '0.0.1'}"

        InModuleScope Plumber -Parameters @{
            BuildRoot    = $script:buildRoot
            ManifestPath = $manifestPath
        } {
            Mock Invoke-PlumberPester {
                [pscustomobject]@{
                    Result       = 'Passed'
                    Containers   = @([pscustomobject]@{Name = 'Tests/Unit/Get-Thing.Tests.ps1'})
                    CodeCoverage = [pscustomobject]@{CoveragePercent = 95}
                }
            }

            $script:moduleManifest = Get-Item $ManifestPath
            $script:moduleFolders = @(
                Join-Path $BuildRoot 'Public'
                Join-Path $BuildRoot 'Private'
            )
            $script:PlumberConfig = @{
                Tasks = @{
                    PesterUnit = @{
                        StreamOutput = $false
                    }
                }
            }

            Invoke-PlumberPesterUnit

            Should -Invoke Invoke-PlumberPester -ParameterFilter {
                $Path -eq (Join-Path $BuildRoot 'Tests/Unit') -and
                    $ModuleManifest -eq (Get-Item $ManifestPath).FullName -and
                    $CodeCoveragePath.Count -eq 2 -and
                    $StreamOutput -eq $false
            }
            $script:pesterResult.Result | Should -Be 'Passed'
        }
    }

    It 'reports failed Pester results' {
        $unitTestPath = Join-Path $script:buildRoot 'Tests/Unit'
        New-Item -Path $unitTestPath -ItemType Directory -Force | Out-Null

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            Mock Invoke-PlumberPester {
                @(
                    [pscustomobject]@{Result = 'Failed'}
                    [pscustomobject]@{Result = 'Passed'}
                )
            }

            $script:moduleManifest = [pscustomobject]@{
                FullName = Join-Path $BuildRoot 'PesterUnitModule.psd1'
            }
            $script:moduleFolders = @()
            $script:PlumberConfig = @{
                Tasks = @{
                    PesterUnit = @{
                        StreamOutput = $true
                    }
                }
            }

            { Invoke-PlumberPesterUnit -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Pester failed with 1 error(s)*'
        }
    }
}
