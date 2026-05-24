BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Select-PlumberDependency' {
    It 'returns all dependencies when no scope is requested' {
        InModuleScope Plumber {
            $dependencies = @(
                @{ ModuleName = 'Core.Dependency'; ModuleVersion = '1.0.0'; Scope = 'Core' }
                @{ ModuleName = 'Task.Dependency'; ModuleVersion = '1.0.0'; Scope = 'PesterUnit' }
            )

            $selected = Select-PlumberDependency -Dependency $dependencies

            $selected.ModuleName | Should -Be @('Core.Dependency', 'Task.Dependency')
        }
    }

    It 'returns core and matching task scoped dependencies' {
        InModuleScope Plumber {
            $dependencies = @(
                @{ ModuleName = 'Core.Dependency'; ModuleVersion = '1.0.0'; Scope = 'Core' }
                @{
                    ModuleName = 'Pester.Dependency'
                    ModuleVersion = '1.0.0'
                    Scope = @(
                        'PesterUnit'
                        'PesterIntegration'
                    )
                }
                @{ ModuleName = 'Yaml.Dependency'; ModuleVersion = '1.0.0'; Scope = 'YAML' }
            )

            $selected = Select-PlumberDependency -Dependency $dependencies -Scope PesterUnit

            $selected.ModuleName | Should -Be @('Core.Dependency', 'Pester.Dependency')
        }
    }

    It 'treats dependencies without scope as core dependencies' {
        InModuleScope Plumber {
            $dependencies = @(
                @{ ModuleName = 'Legacy.Dependency'; ModuleVersion = '1.0.0' }
                @{ ModuleName = 'Yaml.Dependency'; ModuleVersion = '1.0.0'; Scope = 'YAML' }
            )

            $selected = Select-PlumberDependency -Dependency $dependencies -Scope YAML

            $selected.ModuleName | Should -Be @('Legacy.Dependency', 'Yaml.Dependency')
        }
    }
}
