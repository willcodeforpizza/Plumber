# Build and release dependencies for this repository's Plumber tasks.
#
# Plumber's own internal task dependencies are declared separately in
# Plumber.internal.dependencies.psd1 and installed with:
#
#     Install-PlumberDependency
#
# This file is for repository-specific build/release tooling and is installed
# with:
#
#     Install-PlumberDependency -Build

@{
    Modules = @(
        @{
            ModuleName    = 'Plumber.Release'
            ModuleVersion = '0.1.6'
        }
    )
}
