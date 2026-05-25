BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }

    # Pester's Mock needs the target command to exist. Install-PSResource
    # (PSResourceGet) and Install-Module (PowerShellGet v2) are not guaranteed
    # to be present in every test session, so register stubs to mock against.
    InModuleScope Plumber {
        if (-not (Get-Command Install-PSResource -ErrorAction SilentlyContinue)) {
            function script:Install-PSResource {
                param (
                    $Name,
                    $Version,
                    $Scope,
                    [switch] $TrustRepository
                )
                $null = $Name, $Version, $Scope, $TrustRepository
            }
        }
        if (-not (Get-Command Install-Module -ErrorAction SilentlyContinue)) {
            function script:Install-Module {
                param (
                    $Name,
                    $MinimumVersion,
                    $Scope,
                    [switch] $Force,
                    [switch] $SkipPublisherCheck
                )
                $null = $Name, $MinimumVersion, $Scope, $Force, $SkipPublisherCheck
            }
        }
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

    It 'tolerates pre-release version tags on loaded modules' {
        InModuleScope Plumber {
            Mock Get-Module {
                [pscustomobject]@{
                    Name    = 'Example.Dependency'
                    Version = '5.7.1-preview'
                }
            } -ParameterFilter {
                $Name -eq 'Example.Dependency'
            }
            Mock Import-Module {}

            { Import-PlumberDependency -Dependency @(
                @{
                    ModuleName    = 'Example.Dependency'
                    ModuleVersion = '5.7.0'
                }
            ) } | Should -Not -Throw
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

    It 'prefers Install-PSResource when available' {
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
                [pscustomobject]@{ Name = 'Install-PSResource' }
            } -ParameterFilter { $Name -eq 'Install-PSResource' }
            Mock Get-Command {
                [pscustomobject]@{ Name = 'Install-Module' }
            } -ParameterFilter { $Name -eq 'Install-Module' }
            Mock Install-PSResource {}
            Mock Install-Module {}

            Import-PlumberDependency -Dependency @(
                @{
                    ModuleName    = 'Example.Dependency'
                    ModuleVersion = '1.2.3'
                }
            ) -InstallMissing

            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'Example.Dependency' -and
                $Version -eq '[1.2.3,)'
            }
            Should -Invoke Install-Module -Times 0 -Exactly
        }
    }

    It 'falls back to Install-Module when Install-PSResource is unavailable' {
        InModuleScope Plumber {
            $script:importCount = 0
            Mock Get-Module {}
            Mock Import-Module {
                $script:importCount++
                if ($script:importCount -eq 1) {
                    throw 'Dependency missing'
                }
            }
            Mock Get-Command { $null } -ParameterFilter {
                $Name -eq 'Install-PSResource'
            }
            Mock Get-Command {
                [pscustomobject]@{ Name = 'Install-Module' }
            } -ParameterFilter { $Name -eq 'Install-Module' }
            Mock Install-Module {}

            Import-PlumberDependency -Dependency @(
                @{
                    ModuleName    = 'Example.Dependency'
                    ModuleVersion = '1.2.3'
                }
            ) -InstallMissing

            Should -Invoke Install-Module -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'Example.Dependency' -and
                $MinimumVersion -eq '1.2.3'
            }
        }
    }

    It 'throws when neither installer is available' {
        InModuleScope Plumber {
            Mock Get-Module {}
            Mock Import-Module { throw 'Dependency missing' }
            Mock Get-Command { $null } -ParameterFilter {
                $Name -in 'Install-PSResource', 'Install-Module'
            }

            {
                Import-PlumberDependency -Dependency @(
                    @{
                        ModuleName    = 'Example.Dependency'
                        ModuleVersion = '1.2.3'
                    }
                ) -InstallMissing
            } | Should -Throw -ExpectedMessage (
                '*neither Install-PSResource nor Install-Module is available*'
            )
        }
    }
}
