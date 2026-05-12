BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberTaskGroup' {
    It 'returns built-in validation groups' {
        InModuleScope Plumber {
            $groups = @(Get-PlumberTaskGroup)

            $groups.Parent | Should -Contain 'CodeQuality'
            $groups.Parent | Should -Contain 'ReleaseHygiene'
            $groups.Parent | Should -Contain 'Content'
            $groups.Parent | Should -Contain 'ModuleConventions'
            ($groups | Where-Object Parent -EQ 'CodeQuality').Children |
                Should -Contain 'PesterUnit'
        }
    }
}
