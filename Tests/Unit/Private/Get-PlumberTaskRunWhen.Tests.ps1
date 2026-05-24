BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberTaskRunWhen' {
    It 'returns configured RunWhen for built-in tasks' {
        InModuleScope Plumber {
            $script:PlumberConfig = New-PlumberConfig -Config @{
                Tasks = @{
                    ModuleVersion = @{
                        RunWhen = 'OnRelease'
                    }
                }
            }

            Get-PlumberTaskRunWhen -Name ModuleVersion |
                Should -Be 'OnRelease'
        }
    }

    It 'returns configured RunWhen for local task names' {
        InModuleScope Plumber {
            $script:PlumberConfig = New-PlumberConfig -Config @{
                Tasks = @{
                    LocalTask = @{
                        RunWhen = 'Never'
                    }
                }
            }

            Get-PlumberTaskRunWhen -Name LocalTask |
                Should -Be 'Never'
        }
    }

    It 'returns Always for local task names with no explicit config' {
        InModuleScope Plumber {
            $script:PlumberConfig = New-PlumberConfig -Config @{}

            Get-PlumberTaskRunWhen -Name LocalTask |
                Should -Be 'Always'
        }
    }
}
