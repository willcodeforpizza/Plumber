BeforeDiscovery {
    $moduleName = 'FailingModule'
    Get-Module $moduleName | Remove-Module 
    Import-Module "$PSScriptRoot\..\..\$moduleName.psd1" -Force
}

Context "Get-Failure" {
    Describe "Integrates a thing" {
        It "Does not work" {
            $false | Should -Be $true
        }
    }
}