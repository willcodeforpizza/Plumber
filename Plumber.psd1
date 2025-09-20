@{
    RootModule    = 'Plumber.psm1'
    ModuleVersion = '0.0.1'
    GUID          = '03d665a4-c447-470b-acfc-ee7195c019e0'
    Author        = 'WillCodeForPizza'
    CompanyName   = 'WillCodeForPizza'
    Copyright     = '(c) 2025 WillCodeForPizza. All rights reserved.'
    Description   = 'A wrapper around Invoke-Build for PowerShell Pipelines'
    FunctionsToExport = @(
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
