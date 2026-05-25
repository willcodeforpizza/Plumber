# Plumber's own task dependencies.
#
# This file ships inside the Plumber module. It is read at module import time
# by Plumber.psm1's two-phase bootstrap. To install these dependencies run:
#
#     Install-PlumberDependency -Internal
#
# Do not confuse this with the Plumber.dependencies.psd1 file that consumers
# place at the root of their own repositories, which declares the build and
# release modules required by that repository's Plumber tasks.

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
