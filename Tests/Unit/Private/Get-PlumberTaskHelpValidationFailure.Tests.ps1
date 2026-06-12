BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberTaskHelpValidationFailure' {
    BeforeEach {
        $script:taskRoot = Join-Path $TestDrive 'Tasks'
        $script:buildRoot = $TestDrive
        New-Item -Path (Join-Path $script:taskRoot 'CodeQuality') -ItemType Directory -Force |
            Out-Null
    }

    It 'passes when group task includes match task group children' {
        $scopeParameters = @{
            TaskRoot  = $script:taskRoot
            BuildRoot = $script:buildRoot
        }
        InModuleScope Plumber -Parameters $scopeParameters {
            param ($TaskRoot, $BuildRoot)

            $taskFile = New-Item -Path (
                Join-Path $TaskRoot 'CodeQuality/CodeQuality.ps1'
            ) -ItemType File -Force
            $help = [pscustomobject]@{
                Name          = 'CodeQuality'
                Synopsis      = 'Runs code quality validation.'
                Description   = 'Runs validation tasks.'
                Group         = ''
                Includes      = @('PSScriptAnalyzer', 'Backticks', 'LineLength')
                Configuration = ''
                Run           = 'Invoke-Plumber -Task CodeQuality'
                Pass          = ''
                Fail          = ''
            }
            $taskGroup = @(
                @{
                    Parent   = 'CodeQuality'
                    Children = @('PSScriptAnalyzer', 'Backticks', 'LineLength')
                }
            )

            $validationSplat = @{
                Help      = $help
                TaskFile  = $taskFile
                TaskRoot  = $TaskRoot
                BuildRoot = $BuildRoot
                TaskGroup = $taskGroup
            }
            $result = Get-PlumberTaskHelpValidationFailure @validationSplat

            $result | Should -BeNullOrEmpty
        }
    }

    It 'fails when group task includes drift from task group children' {
        $scopeParameters = @{
            TaskRoot  = $script:taskRoot
            BuildRoot = $script:buildRoot
        }
        InModuleScope Plumber -Parameters $scopeParameters {
            param ($TaskRoot, $BuildRoot)

            $taskFile = New-Item -Path (
                Join-Path $TaskRoot 'CodeQuality/CodeQuality.ps1'
            ) -ItemType File -Force
            $help = [pscustomobject]@{
                Name          = 'CodeQuality'
                Synopsis      = 'Runs code quality validation.'
                Description   = 'Runs validation tasks.'
                Group         = ''
                Includes      = @('PSScriptAnalyzer', 'Backticks', 'LineLength')
                Configuration = ''
                Run           = 'Invoke-Plumber -Task CodeQuality'
                Pass          = ''
                Fail          = ''
            }
            $taskGroup = @(
                @{
                    Parent   = 'CodeQuality'
                    Children = @(
                        'PSScriptAnalyzer',
                        'Backticks',
                        'LineLength',
                        'PathSeparator'
                    )
                }
            )

            $validationSplat = @{
                Help      = $help
                TaskFile  = $taskFile
                TaskRoot  = $TaskRoot
                BuildRoot = $BuildRoot
                TaskGroup = $taskGroup
            }
            $result = Get-PlumberTaskHelpValidationFailure @validationSplat

            $result | Should -BeLike '*CodeQuality*INCLUDES must match task group children*'
            $result | Should -BeLike '*expected: PSScriptAnalyzer, Backticks, LineLength, PathSeparator*'
            $result | Should -BeLike '*actual: PSScriptAnalyzer, Backticks, LineLength*'
        }
    }
}
