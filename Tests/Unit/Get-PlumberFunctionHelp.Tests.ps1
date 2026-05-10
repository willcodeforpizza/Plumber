BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
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

    It 'handles missing comment-based help without throwing' {
        $functionPath = Join-Path $TestDrive 'Invoke-NoHelp.ps1'
        @'
function Invoke-NoHelp {
    param (
        [string]
        $Name
    )

    $Name
}
'@ | Set-Content -Path $functionPath

        InModuleScope Plumber -Parameters @{FunctionPath = $functionPath} {
            $help = Get-PlumberFunctionHelp -Path $FunctionPath

            $help.Name | Should -Be 'Invoke-NoHelp'
            $help.Synopsis | Should -BeNullOrEmpty
            $help.Description | Should -BeNullOrEmpty
            $help.Parameters | Should -BeNullOrEmpty
            $help.Examples | Should -BeNullOrEmpty
            $help.HasParameter | Should -BeTrue
        }
    }
}
