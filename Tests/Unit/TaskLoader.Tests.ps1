BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
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

Describe 'Import-PlumberTask' {
    It 'returns task import details when the task is enabled' {
        InModuleScope Plumber {
            $task = Import-PlumberTask -Name JSON -Path 'Content/JSON.ps1' -TaskRoot $TestDrive -Parent Content

            $task.Name | Should -Be 'JSON'
            $task.FullName | Should -Be (Join-Path $TestDrive 'Content/JSON.ps1')
            $task.Parent | Should -Be 'Content'
        }
    }

    It 'returns nothing when the task is excluded' {
        InModuleScope Plumber {
            Import-PlumberTask -Name YAML -Path 'Content/YAML.ps1' -TaskRoot $TestDrive -ExcludeTasks YAML |
                Should -BeNullOrEmpty
        }
    }
}
