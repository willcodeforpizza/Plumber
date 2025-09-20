BeforeDiscovery {
    #TODO: Handle clobbering module when running pipeline on Plumber itself
    #Get-Module Plumber | Remove-Module 
    #Import-Module "$PSScriptRoot\..\..\Plumber.psd1" -Force
}

Context "Invoke-Plumber" {
    Describe "Does a thing" {
        It "Works" {
            $true | Should -Be $true
            #TODO: Write proper tests
        }
    }
}