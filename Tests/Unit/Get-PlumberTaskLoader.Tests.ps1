BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberTaskLoader' {
    It 'returns the task loader script path' {
        $path = Get-PlumberTaskLoader

        Split-Path $path -Leaf | Should -Be 'TaskLoader.ps1'
        Test-Path $path | Should -BeTrue
    }
}
