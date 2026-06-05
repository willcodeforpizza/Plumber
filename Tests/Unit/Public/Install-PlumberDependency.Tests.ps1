BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Install-PlumberDependency' {
    It 'installs Plumber internal dependencies by default' {
        InModuleScope Plumber {
            Mock Import-PlumberDependency {}

            Install-PlumberDependency

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

    It 'installs modules from a repository dependency file with -Build' {
        InModuleScope Plumber {
            $repoRoot = Join-Path $TestDrive 'Repo'
            New-Item -Path $repoRoot -ItemType Directory | Out-Null
            Set-Content -Path (Join-Path $repoRoot 'Plumber.dependencies.psd1') -Value @'
@{
    Modules = @(
        @{
            ModuleName = 'Plumber.Release'
            ModuleVersion = '0.1.6'
        }
    )
}
'@
            Mock Import-PlumberDependency {}

            Install-PlumberDependency -Build -Path $repoRoot

            Should -Invoke Import-PlumberDependency -Times 1 -Exactly -ParameterFilter {
                $InstallMissing -and
                $Dependency.Count -eq 1 -and
                $Dependency[0].ModuleName -eq 'Plumber.Release' -and
                $Dependency[0].ModuleVersion -eq '0.1.6'
            }
        }
    }

    It 'uses the current directory dependency file with -Build by default' {
        InModuleScope Plumber {
            $repoRoot = Join-Path $TestDrive 'RepoDefaultPath'
            New-Item -Path $repoRoot -ItemType Directory | Out-Null
            Set-Content -Path (Join-Path $repoRoot 'Plumber.dependencies.psd1') -Value @'
@{
    Modules = @(
        @{
            ModuleName = 'Plumber.Release'
            ModuleVersion = '0.1.6'
        }
    )
}
'@
            Mock Import-PlumberDependency {}

            Push-Location $repoRoot
            try {
                Install-PlumberDependency -Build
            } finally {
                Pop-Location
            }

            Should -Invoke Import-PlumberDependency -Times 1 -Exactly -ParameterFilter {
                $InstallMissing -and
                $Dependency[0].ModuleName -eq 'Plumber.Release'
            }
        }
    }

    It 'throws when -Path is used without -Build' {
        InModuleScope Plumber {
            {
                Install-PlumberDependency -Path $TestDrive
            } | Should -Throw -ExpectedMessage 'Path is only valid with -Build*'
        }
    }

    It 'throws when the build dependency file is missing' {
        InModuleScope Plumber {
            {
                Install-PlumberDependency -Build -Path $TestDrive
            } | Should -Throw -ExpectedMessage 'Could not find Plumber dependency file*'
        }
    }
}
