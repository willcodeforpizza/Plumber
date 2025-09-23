BeforeDiscovery {
    $moduleName = 'PassingModule'
    #Get-Module $moduleName | Remove-Module
    Import-Module "$PSScriptRoot\..\..\$moduleName.psd1" -Force
}

InModuleScope $moduleName {
    Context "Get-Success" {
        Describe "Does a thing" {
            It "Does work" {
                Mock Get-Service {[PSCustomObject]@{
                    Name = 1
                }}
                Get-Success | Should -Be $null
            }
        }
    }
}
