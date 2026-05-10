@{
    RootModule    = 'Plumber.psm1'
    ModuleVersion = '0.0.9'
    GUID          = '03d665a4-c447-470b-acfc-ee7195c019e0'
    Author        = 'WillCodeForPizza'
    CompanyName   = 'WillCodeForPizza'
    Copyright     = '(c) 2025 WillCodeForPizza. All rights reserved.'
    Description   = 'A set of Invoke-Build tasks for Powershell validation pipelines'
    FunctionsToExport = @(
        'Get-PlumberTaskLoader'
        'Invoke-Plumber'
    )
    PrivateData = @{
        PSData = @{
            PublishSource = 'Local'
            # PublishSource = 'PowershellGallery'
            # Tags = @()
            # LicenseUri = ''
            # ProjectUri = ''
            # IconUri = ''
            # ReleaseNotes = ''
            # ExternalModuleDependencies = @()
        }
    }
}
