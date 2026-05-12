BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Test-PlumberTaskEnabled' {
    It 'returns true when the task is not excluded' {
        InModuleScope Plumber {
            Test-PlumberTaskEnabled -Name JSON -ExcludeTasks YAML |
                Should -BeTrue
        }
    }

    It 'returns false when the task is excluded' {
        InModuleScope Plumber {
            Test-PlumberTaskEnabled -Name YAML -ExcludeTasks YAML |
                Should -BeFalse
        }
    }
}
