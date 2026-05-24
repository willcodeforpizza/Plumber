BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Import-PlumberTask' {
    It 'returns task import details when the task is enabled' {
        InModuleScope Plumber {
            $taskSplat = @{
                Name        = 'JSON'
                Path        = 'Content/JSON.ps1'
                TaskRoot    = $TestDrive
                Parent      = 'Content'
                EnforceWhen = 'Always'
            }
            $task = Import-PlumberTask @taskSplat

            $task.Name | Should -Be 'JSON'
            $task.FullName | Should -Be (Join-Path $TestDrive 'Content/JSON.ps1')
            $task.Parent | Should -Be 'Content'
            $task.EnforceWhen | Should -Be 'Always'
            $task.ShouldRun | Should -BeTrue
        }
    }

    It 'marks task imports as skipped when EnforceWhen disables the task' {
        InModuleScope Plumber {
            $task = Import-PlumberTask -Name YAML -Path 'Content/YAML.ps1' -TaskRoot $TestDrive -EnforceWhen Never

            $task.Name | Should -Be 'YAML'
            $task.EnforceWhen | Should -Be 'Never'
            $task.ShouldRun | Should -BeFalse
        }
    }
}
