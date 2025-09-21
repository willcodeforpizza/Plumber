BeforeDiscovery {
    $moduleName = 'PassingModule'
    Get-Module $moduleName | Remove-Module 
    Import-Module "$PSScriptRoot\..\..\$moduleName.psd1" -Force
}

Context "Get-Success" {
    Describe "Integrates a thing" {
        It "Does work" {
            $true | Should -Be $true
        }
    }
}