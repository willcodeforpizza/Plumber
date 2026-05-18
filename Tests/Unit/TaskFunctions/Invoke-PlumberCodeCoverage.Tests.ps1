BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberCodeCoverage' {
    It 'reports when no Pester unit test results are found' {
        InModuleScope Plumber {
            function Write-Build {
                param ($Color, $Message)
                $null = $Color
                $null = $Message
            }
            Mock Write-Build {}

            $script:pesterResult = $null

            Invoke-PlumberCodeCoverage

            Should -Invoke Write-Build -ParameterFilter {
                $Color -eq 'Yellow' -and $Message -eq 'No Pester unit test results found'
            }
        }
    }

    It 'passes when coverage meets the configured minimum' {
        InModuleScope Plumber {
            $script:PlumberConfig = @{
                Tasks = @{
                    CodeCoverage = @{
                        Minimum = 75
                    }
                }
            }
            $script:pesterResult = @(
                [pscustomobject]@{
                    Containers   = @([pscustomobject]@{Name = 'Public/Get-Thing.ps1'})
                    CodeCoverage = [pscustomobject]@{CoveragePercent = 80}
                }
            )

            { Invoke-PlumberCodeCoverage -ErrorAction Stop } | Should -Not -Throw
        }
    }

    It 'reports coverage below the configured minimum' {
        InModuleScope Plumber {
            $script:PlumberConfig = @{
                Tasks = @{
                    CodeCoverage = @{
                        Minimum = 90
                    }
                }
            }
            $script:pesterResult = @(
                [pscustomobject]@{
                    Containers   = @([pscustomobject]@{Name = 'Public/Get-Thing.ps1'})
                    CodeCoverage = [pscustomobject]@{CoveragePercent = 80}
                }
            )

            { Invoke-PlumberCodeCoverage -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*80% coverage for Public/Get-Thing.ps1*'
        }
    }
}
