# Plumber's own internal task dependencies.
#
# This file ships inside the Plumber module. It is used by Invoke-Plumber's
# command-boundary dependency check and by the default Install-PlumberDependency
# bootstrap command:
#
#     Install-PlumberDependency
#
# Repository build/release dependencies belong in a root-level
# Plumber.dependencies.psd1 file and are installed with:
#
#     Install-PlumberDependency -Build

@{
    Modules = @(
        @{
            ModuleName    = 'InvokeBuild'
            ModuleVersion = '5.14.23'
        }
        @{
            ModuleName    = 'Pester'
            ModuleVersion = '5.7.1'
        }
        @{
            ModuleName    = 'PSScriptAnalyzer'
            ModuleVersion = '1.24.0'
        }
        @{
            ModuleName    = 'powershell-yaml'
            ModuleVersion = '0.4.12'
        }
    )
}
