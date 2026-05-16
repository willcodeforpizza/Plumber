BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Import-PlumberDependency' {
    It 'accepts dependencies that are already loaded' {
        InModuleScope Plumber {
            Mock Get-Module {
                [pscustomobject]@{
                    Name    = 'Example.Dependency'
                    Version = [version]'1.2.3'
                }
            } -ParameterFilter {
                $Name -eq 'Example.Dependency'
            }
            Mock Import-Module {}

            Import-PlumberDependency -Dependency @(
                @{
                    ModuleName    = 'Example.Dependency'
                    ModuleVersion = '1.2.3'
                }
            )

            Should -Invoke Import-Module -Times 0 -Exactly
        }
    }

    It 'imports dependencies that are already available' {
        InModuleScope Plumber {
            Mock Get-Module {}
            Mock Import-Module {}

            Import-PlumberDependency -Dependency @(
                @{
                    ModuleName    = 'Example.Dependency'
                    ModuleVersion = '1.2.3'
                }
            )

            Should -Invoke Import-Module -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'Example.Dependency' -and
                $MinimumVersion -eq '1.2.3'
            }
        }
    }

    It 'installs missing dependencies when requested' {
        InModuleScope Plumber {
            $script:importCount = 0
            Mock Get-Module {}
            Mock Import-Module {
                $script:importCount++
                if ($script:importCount -eq 1) {
                    throw 'Dependency missing'
                }
            }
            Mock Get-Command {
                [pscustomobject]@{ Name = 'Install-Module' }
            } -ParameterFilter {
                $Name -eq 'Install-Module'
            }
            Mock Install-PlumberModuleDependency {}

            Import-PlumberDependency -Dependency @(
                @{
                    ModuleName    = 'Example.Dependency'
                    ModuleVersion = '1.2.3'
                }
            ) -InstallMissing

            Should -Invoke Install-PlumberModuleDependency -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'Example.Dependency' -and
                $RequiredVersion -eq '1.2.3'
            }
            Should -Invoke Import-Module -Times 2 -Exactly
        }
    }

    It 'throws when a missing dependency cannot be installed' {
        InModuleScope Plumber {
            Mock Get-Module {}
            Mock Import-Module {
                throw 'Dependency missing'
            }
            Mock Get-Command {
                $null
            } -ParameterFilter {
                $Name -eq 'Install-Module'
            }

            {
                Import-PlumberDependency -Dependency @(
                    @{
                        ModuleName    = 'Example.Dependency'
                        ModuleVersion = '1.2.3'
                    }
                ) -InstallMissing
            } | Should -Throw -ExpectedMessage (
                'Could not load Example.Dependency v1.2.3 and Install-Module is not available.*'
            )
        }
    }
}
