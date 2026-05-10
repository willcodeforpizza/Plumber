BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Test-PlumberFunctionHelp' {
    It 'requires only synopsis when full help is not required' {
        InModuleScope Plumber {
            $help = [pscustomobject]@{
                Name        = 'Invoke-Thing'
                Synopsis    = 'Invokes a thing.'
                Description = $null
                Parameters  = @()
                Examples    = @()
                HasParameter = $true
            }

            Test-PlumberFunctionHelp -Help $help |
                Should -BeNullOrEmpty
        }
    }

    It 'requires description, parameters and examples for full help' {
        InModuleScope Plumber {
            $help = [pscustomobject]@{
                Name        = 'Invoke-Thing'
                Synopsis    = 'Invokes a thing.'
                Description = $null
                Parameters  = @()
                Examples    = @()
                HasParameter = $true
            }

            $result = Test-PlumberFunctionHelp -Help $help -RequireFullHelp

            $result | Should -Contain 'Invoke-Thing: Missing help description'
            $result | Should -Contain 'Invoke-Thing: Missing help parameter documentation'
            $result | Should -Contain 'Invoke-Thing: Missing help example'
        }
    }

    It 'reports missing synopsis' {
        InModuleScope Plumber {
            $help = [pscustomobject]@{
                Name        = 'Invoke-Thing'
                Synopsis    = $null
                Description = 'Description'
                Parameters  = @('Name')
                Examples    = @('Example')
                HasParameter = $true
            }

            Test-PlumberFunctionHelp -Help $help |
                Should -Contain 'Invoke-Thing: Missing help synopsis'
        }
    }

    It 'does not require parameter help for parameterless functions' {
        InModuleScope Plumber {
            $help = [pscustomobject]@{
                Name         = 'Invoke-Thing'
                Synopsis     = 'Invokes a thing.'
                Description  = 'Description'
                Parameters   = @()
                Examples     = @('Example')
                HasParameter = $false
            }

            Test-PlumberFunctionHelp -Help $help -RequireFullHelp |
                Should -BeNullOrEmpty
        }
    }
}
