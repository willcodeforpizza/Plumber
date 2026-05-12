BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberTaskHelp' {
    BeforeAll {
        $script:assetRoot = Join-Path $PSScriptRoot '../../Assets/TaskHelp'
    }

    It 'reads group task help from a task file' {
        InModuleScope Plumber -Parameters @{AssetRoot = $script:assetRoot} {
            $taskPath = Join-Path $AssetRoot 'Content.ps1'
            $help = Get-PlumberTaskHelp -Path $taskPath

            $help.Name | Should -Be 'Content'
            $help.Synopsis | Should -Be 'Runs content validation tasks.'
            $help.Description | Should -Match 'repository content files'
            $help.Includes | Should -Be @('JSON', 'JSONSchema', 'YAML')
            $help.Run | Should -Match 'Invoke-Plumber -Task Content'
            $help.Group | Should -BeNullOrEmpty
            $help.Pass | Should -BeNullOrEmpty
            $help.Fail | Should -BeNullOrEmpty
            $help.IsGroup | Should -BeTrue
        }
    }

    It 'reads leaf task help from a task file' {
        InModuleScope Plumber -Parameters @{AssetRoot = $script:assetRoot} {
            $taskPath = Join-Path $AssetRoot 'YAML.ps1'
            $help = Get-PlumberTaskHelp -Path $taskPath

            $help.Name | Should -Be 'YAML'
            $help.Synopsis | Should -Be 'Validates YAML files.'
            $help.Description | Should -Match 'serialized back to YAML'
            $help.Group | Should -Be 'Content'
            $help.Configuration | Should -Be 'None.'
            $help.Run | Should -Match 'Invoke-Plumber -Task YAML'
            $help.Pass | Should -Match '```yaml'
            $help.Pass | Should -Match 'task: validate'
            $help.Fail | Should -Match 'invalid'
            $help.Includes | Should -BeNullOrEmpty
            $help.IsGroup | Should -BeFalse
        }
    }

    It 'gets the task name from the file name' {
        InModuleScope Plumber -Parameters @{AssetRoot = $script:assetRoot} {
            $taskPath = Join-Path $AssetRoot 'YAML.ps1'
            $help = Get-PlumberTaskHelp -Path $taskPath

            $help.Name | Should -Be 'YAML'
        }
    }

    It 'supports native Invoke-Build task syntax' {
        InModuleScope Plumber -Parameters @{AssetRoot = $script:assetRoot} {
            $taskPath = Join-Path $AssetRoot 'NativeTask.ps1'
            $help = Get-PlumberTaskHelp -Path $taskPath

            $help.Name | Should -Be 'NativeTask'
            $help.Run | Should -Match 'Invoke-Plumber -Task NativeTask'
        }
    }

    It 'preserves fenced code blocks in sections' {
        InModuleScope Plumber -Parameters @{AssetRoot = $script:assetRoot} {
            $taskPath = Join-Path $AssetRoot 'YAML.ps1'
            $help = Get-PlumberTaskHelp -Path $taskPath

            $help.Pass | Should -Match '```yaml'
            $help.Pass | Should -Match 'steps:'
            $help.Pass | Should -Match '```$'
        }
    }

    It 'normalizes common indentation in multiline sections' {
        InModuleScope Plumber -Parameters @{AssetRoot = $script:assetRoot} {
            $taskPath = Join-Path $AssetRoot 'YAML.ps1'
            $help = Get-PlumberTaskHelp -Path $taskPath

            $expected = @'
Finds `.yml` and `.yaml` files under the build root and verifies that each
file can be parsed from YAML and serialized back to YAML.
'@
            $help.Description | Should -Be $expected
        }
    }

    It 'throws when task documentation is missing' {
        InModuleScope Plumber -Parameters @{AssetRoot = $script:assetRoot} {
            $taskPath = Join-Path $AssetRoot 'MissingDocumentation.ps1'

            {Get-PlumberTaskHelp -Path $taskPath} |
                Should -Throw -ExpectedMessage 'No Plumber task documentation block found*'
        }
    }

    It 'throws when a task command is missing' {
        InModuleScope Plumber -Parameters @{AssetRoot = $script:assetRoot} {
            $taskPath = Join-Path $AssetRoot 'MissingTask.ps1'

            {Get-PlumberTaskHelp -Path $taskPath} |
                Should -Throw -ExpectedMessage 'No Plumber task command found*'
        }
    }

    It 'throws when the task file cannot be parsed' {
        InModuleScope Plumber -Parameters @{AssetRoot = $script:assetRoot} {
            $taskPath = Join-Path $AssetRoot 'InvalidPowerShell.ps1'

            {Get-PlumberTaskHelp -Path $taskPath} |
                Should -Throw -ExpectedMessage 'Failed to parse task help*'
        }
    }
}
