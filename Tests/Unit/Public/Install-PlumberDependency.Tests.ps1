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
            Scope = 'Release'
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

    It 'installs only core and requested task scope dependencies' {
        InModuleScope Plumber {
            $repoRoot = Join-Path $TestDrive 'ScopedRepo'
            New-Item -Path $repoRoot -ItemType Directory | Out-Null
            Set-Content -Path (Join-Path $repoRoot 'Plumber.dependencies.psd1') -Value @'
@{
    Modules = @(
        @{
            ModuleName = 'Core.Dependency'
            ModuleVersion = '1.0.0'
            Scope = 'Core'
        }
        @{
            ModuleName = 'Yaml.Dependency'
            ModuleVersion = '1.0.0'
            Scope = 'YAML'
        }
        @{
            ModuleName = 'Release.Dependency'
            ModuleVersion = '1.0.0'
            Scope = 'Release'
        }
    )
}
'@
            Mock Import-PlumberDependency {}

            Install-PlumberDependency -Path $repoRoot -Scope YAML

            Should -Invoke Import-PlumberDependency -Times 1 -Exactly -ParameterFilter {
                $Dependency.Count -eq 2 -and
                $Dependency[0].ModuleName -eq 'Core.Dependency' -and
                $Dependency[1].ModuleName -eq 'Yaml.Dependency'
            }
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
