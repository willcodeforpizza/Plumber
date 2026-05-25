BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Install-PlumberDependency' {
    It 'installs modules from a repository dependency file' {
        InModuleScope Plumber {
            $repoRoot = Join-Path $TestDrive 'Repo'
            New-Item -Path $repoRoot -ItemType Directory | Out-Null
            Set-Content -Path (Join-Path $repoRoot 'Plumber.dependencies.psd1') -Value @'
@{
    Modules = @(
        @{
            ModuleName = 'Plumber.Release'
            ModuleVersion = '0.1.4'
        }
    )
}
'@
            Mock Import-PlumberDependency {}

            Install-PlumberDependency -Path $repoRoot

            Should -Invoke Import-PlumberDependency -Times 1 -Exactly -ParameterFilter {
                $InstallMissing -and
                $Dependency.Count -eq 1 -and
                $Dependency[0].ModuleName -eq 'Plumber.Release' -and
                $Dependency[0].ModuleVersion -eq '0.1.4'
            }
        }
    }

    It 'installs Plumber internal dependencies with -Internal' {
        InModuleScope Plumber {
            Mock Import-PlumberDependency {}

            Install-PlumberDependency -Internal

            $expectedNames = @(
                'InvokeBuild', 'Pester', 'PSScriptAnalyzer', 'powershell-yaml'
            )
            Should -Invoke Import-PlumberDependency -Times 1 -Exactly -ParameterFilter {
                $InstallMissing -and
                ($Dependency | ForEach-Object { $_.ModuleName }) -join ',' -eq
                    ($expectedNames -join ',')
            }
        }
    }

    It '-Internal ignores -Path' {
        InModuleScope Plumber {
            Mock Import-PlumberDependency {}

            $bogusPath = Join-Path $TestDrive 'does-not-exist'
            { Install-PlumberDependency -Internal -Path $bogusPath } |
                Should -Not -Throw

            Should -Invoke Import-PlumberDependency -Times 1 -Exactly
        }
    }

    It 'throws when the dependency file is missing' {
        InModuleScope Plumber {
            {
                Install-PlumberDependency -Path $TestDrive
            } | Should -Throw -ExpectedMessage 'Could not find Plumber dependency file*'
        }
    }
}
