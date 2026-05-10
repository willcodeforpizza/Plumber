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

Describe 'Get-PlumberFunctionHelp' {
    It 'reads comment-based help from a function file' {
        $functionPath = Join-Path $TestDrive 'Invoke-Thing.ps1'
        @'
function Invoke-Thing {
    <#
        .SYNOPSIS
        Invokes a thing.

        .DESCRIPTION
        Invokes a thing for tests.

        .PARAMETER Name
        The thing name.

        .EXAMPLE
        Invoke-Thing -Name Test

        Invokes a test thing.
    #>
    param (
        [string]
        $Name
    )

    $Name
}
'@ | Set-Content -Path $functionPath

        InModuleScope Plumber -Parameters @{FunctionPath = $functionPath} {
            $help = Get-PlumberFunctionHelp -Path $FunctionPath

            $help.Name | Should -Be 'Invoke-Thing'
            $help.Synopsis | Should -Be 'Invokes a thing.'
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Parameters | Should -Contain 'Name'
            $help.Examples | Should -Not -BeNullOrEmpty
            $help.HasParameter | Should -BeTrue
        }
    }
}
