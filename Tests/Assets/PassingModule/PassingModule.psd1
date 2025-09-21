@{
    RootModule    = 'PassingModule.psm1'
    ModuleVersion = '1.1.1'
    GUID          = '65b499f8-83c1-4b3f-a222-b83d460c6454'
    Author        = 'WillCodeForPizza'
    CompanyName   = 'WillCodeForPizza'
    Copyright     = '(c) 2025 WillCodeForPizza. All rights reserved.'
    Description   = 'Example of a failing module for Plumber'
    FunctionsToExport = @(
        'Get-Success'
    )
    PrivateData = @{
        PSData = @{
            PublishSource = 'Local'
            # Tags = @()
            # LicenseUri = ''
            # ProjectUri = ''
            # IconUri = ''
            # ReleaseNotes = ''
            # ExternalModuleDependencies = @()
        }
    }
}
