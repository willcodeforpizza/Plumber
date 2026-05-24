@{
    Modules = @(
        @{
            ModuleName    = 'InvokeBuild'
            ModuleVersion = '5.14.23'
            Scope         = 'Core'
        }
        @{
            ModuleName    = 'Pester'
            ModuleVersion = '5.7.1'
            Scope         = @('PesterUnit', 'PesterIntegration', 'CodeCoverage')
        }
        @{
            ModuleName    = 'PSScriptAnalyzer'
            ModuleVersion = '1.24.0'
            Scope         = 'PSScriptAnalyzer'
        }
        @{
            ModuleName    = 'powershell-yaml'
            ModuleVersion = '0.4.12'
            Scope         = 'YAML'
        }
    )
}
