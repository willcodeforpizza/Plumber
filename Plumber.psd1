@{
    RootModule    = 'Plumber.psm1'
    ModuleVersion = '0.0.33'
    GUID          = '03d665a4-c447-470b-acfc-ee7195c019e0'
    Author        = 'WillCodeForPizza'
    CompanyName   = 'WillCodeForPizza'
    Copyright     = '(c) 2025 WillCodeForPizza. All rights reserved.'
    Description   = 'A set of Invoke-Build tasks for Powershell validation pipelines'
    FunctionsToExport = @(
        'Get-PlumberTaskLoader'
        'Install-PlumberDependency'
        'Invoke-Plumber'
    )
    ModuleList = @(
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
    PrivateData = @{
        PSData = @{
            Tags = @('Validation', 'Pipeline', 'Invoke-Build')
            LicenseUri = 'https://github.com/willcodeforpizza/Plumber/blob/main/LICENSE'
            ProjectUri = 'https://github.com/willcodeforpizza/Plumber'
            ReleaseNotes = 'https://github.com/willcodeforpizza/Plumber/blob/main/CHANGELOG.md'
        }
    }
}
