BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberTaskEnforceWhen' {
    It 'returns configured EnforceWhen for built-in tasks' {
        InModuleScope Plumber {
            $script:PlumberConfig = New-PlumberConfig -Config @{
                Tasks = @{
                    ModuleVersion = @{
                        EnforceWhen = 'OnRelease'
                    }
                }
            }

            Get-PlumberTaskEnforceWhen -Name ModuleVersion |
                Should -Be 'OnRelease'
        }
    }

    It 'returns configured EnforceWhen for local task names' {
        InModuleScope Plumber {
            $script:PlumberConfig = New-PlumberConfig -Config @{
                Tasks = @{
                    LocalTask = @{
                        EnforceWhen = 'Never'
                    }
                }
            }

            Get-PlumberTaskEnforceWhen -Name LocalTask |
                Should -Be 'Never'
        }
    }

    It 'returns Always for local task names with no explicit config' {
        InModuleScope Plumber {
            $script:PlumberConfig = New-PlumberConfig -Config @{}

            Get-PlumberTaskEnforceWhen -Name LocalTask |
                Should -Be 'Always'
        }
    }
}
