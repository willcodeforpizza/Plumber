BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberModuleVersion' {
    It 'errors when PSGallery source cannot find the module' {
        InModuleScope Plumber {
            Mock Find-Module {}

            $script:PlumberConfig = @{
                Tasks = @{
                    ModuleVersion = @{
                        Source = 'PSGallery'
                    }
                }
            }
            $script:moduleName = 'MissingModule'
            $script:psd1 = @{
                ModuleVersion = '1.0.0'
            }

            { Invoke-PlumberModuleVersion -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*MissingModule is not published to PSGallery*'
        }
    }

    It 'passes when 3-segment manifest is greater than 4-segment PSGallery version' {
        InModuleScope Plumber {
            Mock Find-Module {
                [pscustomobject]@{
                    Name    = 'BumpedVersionModule'
                    Version = [version]'0.0.35.0'
                }
            }

            $script:PlumberConfig = @{
                Tasks = @{
                    ModuleVersion = @{
                        Source = 'PSGallery'
                    }
                }
            }
            $script:moduleName = 'BumpedVersionModule'
            $script:psd1 = @{
                ModuleVersion = '0.0.36'
            }

            { Invoke-PlumberModuleVersion -ErrorAction Stop } | Should -Not -Throw
        }
    }

    It 'uses merge-readiness wording when the manifest version is already published' {
        InModuleScope Plumber {
            Mock Find-Module {
                [pscustomobject]@{
                    Name    = 'PublishedVersionModule'
                    Version = [version]'1.2.3'
                }
            }

            $script:PlumberConfig = @{
                Tasks = @{
                    ModuleVersion = @{
                        Source = 'PSGallery'
                    }
                }
            }
            $script:moduleName = 'PublishedVersionModule'
            $script:psd1 = @{
                ModuleVersion = '1.2.3'
            }

            { Invoke-PlumberModuleVersion -ErrorAction Stop } |
                Should -Throw -ExpectedMessage (
                    '*ModuleVersion is not merge-ready. PSD1 version 1.2.3 ' +
                    'must be greater than PSGallery version 1.2.3 before this change is merged.*'
                )
        }
    }
}
