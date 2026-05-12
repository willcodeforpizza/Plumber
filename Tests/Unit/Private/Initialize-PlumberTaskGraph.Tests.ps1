BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Initialize-PlumberTaskGraph' {
    It 'creates task job buckets used by the loader' {
        InModuleScope Plumber {
            $graph = Initialize-PlumberTaskGraph

            $graph.Keys | Should -Contain 'CodeQuality'
            $graph.Keys | Should -Contain 'ReleaseHygiene'
            $graph.Keys | Should -Contain 'Content'
            $graph.Keys | Should -Contain 'ModuleConventions'
            $graph.Keys | Should -Contain 'Local'
            $graph.Validate | Should -Be @('SetVariables')
        }
    }
}
