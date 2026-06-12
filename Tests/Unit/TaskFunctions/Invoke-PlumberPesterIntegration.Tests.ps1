BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberPesterIntegration' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'PesterIntegrationModule'
        Remove-Item -Path $script:buildRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $script:buildRoot -ItemType Directory -Force | Out-Null
    }

    It 'reports when no integration tests are found' {
        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            function Write-Build {
                param ($Color, $Message)
                $null = $Color
                $null = $Message
            }
            Mock Write-Build {}
            Mock Invoke-PlumberPester {}

            Invoke-PlumberPesterIntegration

            Should -Invoke Write-Build -ParameterFilter {
                $Color -eq 'Yellow' -and $Message -eq 'No integration tests found'
            }
            Should -Not -Invoke Invoke-PlumberPester
        }
    }

    It 'runs integration tests with the resolved manifest and stream output config' {
        $integrationTestPath = Join-Path $script:buildRoot 'Tests/Integration'
        New-Item -Path $integrationTestPath -ItemType Directory -Force | Out-Null
        $manifestPath = Join-Path $script:buildRoot 'src/PesterIntegrationModule.psd1'
        New-Item -Path (Join-Path $script:buildRoot 'src') -ItemType Directory -Force | Out-Null
        Set-Content -Path $manifestPath -Value "@{ModuleVersion = '0.0.1'}"

        InModuleScope Plumber -Parameters @{
            BuildRoot    = $script:buildRoot
            ManifestPath = $manifestPath
        } {
            Mock Invoke-PlumberPester {
                [pscustomobject]@{
                    Result = 'Passed'
                }
            }

            $script:moduleManifest = Get-Item $ManifestPath
            $script:PlumberConfig = @{
                Tasks = @{
                    PesterIntegration = @{
                        StreamOutput = $false
                    }
                }
            }

            Invoke-PlumberPesterIntegration

            Should -Invoke Invoke-PlumberPester -ParameterFilter {
                $Path -eq (Join-Path $BuildRoot 'Tests/Integration') -and
                    $ModuleManifest -eq (Get-Item $ManifestPath).FullName -and
                    $StreamOutput -eq $false
            }
        }
    }

    It 'reports failed Pester results' {
        $integrationTestPath = Join-Path $script:buildRoot 'Tests/Integration'
        New-Item -Path $integrationTestPath -ItemType Directory -Force | Out-Null

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            Mock Invoke-PlumberPester {
                @(
                    [pscustomobject]@{Result = 'Failed'}
                    [pscustomobject]@{Result = 'Passed'}
                )
            }

            $script:moduleManifest = [pscustomobject]@{
                FullName = Join-Path $BuildRoot 'PesterIntegrationModule.psd1'
            }
            $script:PlumberConfig = @{
                Tasks = @{
                    PesterIntegration = @{
                        StreamOutput = $true
                    }
                }
            }

            { Invoke-PlumberPesterIntegration -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Pester failed with 1 error(s)*'
        }
    }
}
