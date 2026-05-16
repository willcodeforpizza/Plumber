BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-Plumber' {
    BeforeEach {
        InModuleScope Plumber {
            $script:mockBuildResult = [pscustomobject]@{
                Tasks = @(
                    [pscustomobject]@{
                        Name  = 'Validate'
                        Error = $null
                    }
                )
            }

            Mock Invoke-PlumberBuild {
                $script:mockBuildResult
            }
        }
    }

    It 'runs the Validate task by default' {
        InModuleScope Plumber {
            Invoke-Plumber | Should -Match 'Plumber validation passed'

            Should -Invoke Invoke-PlumberBuild -Times 1 -Exactly -ParameterFilter {
                $Task.Count -eq 1 -and
                $Task[0] -eq 'Validate' -and
                (Split-Path $BuildFile -Leaf) -eq 'Plumber.build.ps1' -and
                -not $RawOutput
            }
        }
    }

    It 'uses an explicit build file when provided' {
        $moduleRoot = Join-Path $TestDrive 'ExplicitModule'
        New-Item -Path $moduleRoot -ItemType Directory | Out-Null
        Set-Content -Path (Join-Path $moduleRoot 'custom.build.ps1') -Value ''

        Push-Location $moduleRoot
        try {
            InModuleScope Plumber {
                Invoke-Plumber -BuildFile 'custom.build.ps1' |
                    Should -Match 'Plumber validation passed'

                Should -Invoke Invoke-PlumberBuild -Times 1 -Exactly -ParameterFilter {
                    (Split-Path $BuildFile -Leaf) -eq 'custom.build.ps1'
                }
            }
        } finally {
            Pop-Location
        }
    }

    It 'passes explicit tasks to the build runner' {
        InModuleScope Plumber {
            Invoke-Plumber -Task JSON, YAML | Should -Match 'Plumber validation passed'

            Should -Invoke Invoke-PlumberBuild -Times 1 -Exactly -ParameterFilter {
                $Task.Count -eq 2 -and
                $Task[0] -eq 'JSON' -and
                $Task[1] -eq 'YAML'
            }
        }
    }

    It 'passes local task names to the build runner' {
        InModuleScope Plumber {
            Invoke-Plumber -Task local -OutputMode Raw | Should -Match 'Validate'

            Should -Invoke Invoke-PlumberBuild -Times 1 -Exactly -ParameterFilter {
                $Task.Count -eq 1 -and
                $Task[0] -eq 'local' -and
                $RawOutput
            }
        }
    }

    It 'writes an error when any build task fails' {
        InModuleScope Plumber {
            $script:mockBuildResult = [pscustomobject]@{
                Tasks = @(
                    [pscustomobject]@{
                        Name  = 'ToDo'
                        Error = 'Found TODO'
                    }
                )
            }

            {Invoke-Plumber -Task ToDo -ErrorAction Stop} |
                Should -Throw -ExpectedMessage 'Build failed!'
        }
    }

    It 'writes full failure details in summary mode before throwing' {
        InModuleScope Plumber {
            $longError = @(
                'PSD1 version might be out of date.'
                'Expected version marker: 1234567890abcdefghijklmnopqrstuvwxyz'
                'Actual version marker: zyxwvutsrqponmlkjihgfedcba0987654321'
            ) -join [Environment]::NewLine
            $script:mockBuildResult = [pscustomobject]@{
                Tasks = @(
                    [pscustomobject]@{
                        Name  = 'SetVariables'
                        Error = $null
                    }
                    [pscustomobject]@{
                        Name  = 'ModuleVersion'
                        Error = $longError
                    }
                )
            }

            $output = try {
                Invoke-Plumber -Task Validate
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }

            $output | Should -Contain 'Plumber validation failed.'
            $output | Should -Contain 'ModuleVersion:'
            $output | Should -Contain $longError
            $output | Should -Contain 'Passed: 1. Failed: 1.'
        }
    }

    It 'writes JSON output when requested' {
        InModuleScope Plumber {
            $result = Invoke-Plumber -OutputMode Json | ConvertFrom-Json

            $result.Success | Should -BeTrue
            $result.Passed | Should -Be 1
            $result.Tasks[0].Name | Should -Be 'Validate'
        }
    }

    It 'writes all task rows in table mode' {
        InModuleScope Plumber {
            Invoke-Plumber -OutputMode Table | Should -Match 'Validate'
        }
    }

    It 'requests raw build output in raw mode' {
        InModuleScope Plumber {
            Invoke-Plumber -OutputMode Raw | Should -Match 'Validate'

            Should -Invoke Invoke-PlumberBuild -Times 1 -Exactly -ParameterFilter {
                $RawOutput
            }
        }
    }

    It 'requests raw build output and writes concise output in CI mode' {
        InModuleScope Plumber {
            Invoke-Plumber -OutputMode CI | Should -Match 'Plumber validation passed'

            Should -Invoke Invoke-PlumberBuild -Times 1 -Exactly -ParameterFilter {
                $RawOutput
            }
        }
    }

    It 'reloads result helpers when build execution removes them' {
        InModuleScope Plumber {
            Mock Invoke-PlumberBuild {
                Remove-Item Function:\ConvertTo-PlumberResult -Force
                Remove-Item Function:\Write-PlumberResult -Force
                $script:mockBuildResult
            }

            Invoke-Plumber | Should -Match 'Plumber validation passed'
        }
    }

    It 'passes unknown task names to the build runner' {
        InModuleScope Plumber {
            Invoke-Plumber -Task NotARealTask | Should -Match 'Plumber validation passed'

            Should -Invoke Invoke-PlumberBuild -Times 1 -Exactly -ParameterFilter {
                $Task.Count -eq 1 -and
                $Task[0] -eq 'NotARealTask'
            }
        }
    }
}

Describe 'Invoke-PlumberBuild' {
    It 'runs Invoke-Build through the resolved command and returns the build result' {
        InModuleScope Plumber {
            Mock Get-Command {
                {
                    param (
                        [string[]]
                        $Task,

                        [string]
                        $File,

                        [string]
                        $Result
                    )

                    if (-not $File) {
                        throw 'Build file is required'
                    }

                    Set-Variable -Name $Result -Scope 1 -Value ([pscustomobject]@{
                        Tasks = @(
                            [pscustomobject]@{
                                Name  = $Task[0]
                                Error = $null
                            }
                        )
                    })
                }
            } -ParameterFilter {
                $Name -eq 'Invoke-Build'
            }

            $buildFile = Join-Path $TestDrive 'wrapper.build.ps1'
            $result = Invoke-PlumberBuild -Task WrapperSmoke -BuildFile $BuildFile

            $result.Tasks.Name | Should -Contain 'WrapperSmoke'
            $result.Tasks.Error | Should -BeNullOrEmpty
        }
    }

    It 'runs Invoke-Build through an alias definition path' {
        InModuleScope Plumber {
            $invokeBuildPath = Join-Path $TestDrive 'Invoke-Build.ps1'
            Set-Content -Path $invokeBuildPath -Value @(
                'param ('
                '    [string[]]'
                '    $Task,'
                ''
                '    [string]'
                '    $File,'
                ''
                '    [string]'
                '    $Result'
                ')'
                'Set-Variable -Name $Result -Scope 1 -Value ([pscustomobject]@{'
                '    Tasks = @('
                '        [pscustomobject]@{'
                '            Name = $Task[0]'
                '            Error = $null'
                '        }'
                '    )'
                '})'
            )
            Mock Get-Command {
                [pscustomobject]@{
                    CommandType = 'Alias'
                    Definition  = $invokeBuildPath
                }
            } -ParameterFilter {
                $Name -eq 'Invoke-Build'
            }

            $buildFile = Join-Path $TestDrive 'wrapper.build.ps1'
            $result = Invoke-PlumberBuild -Task AliasSmoke -BuildFile $BuildFile

            $result.Tasks.Name | Should -Contain 'AliasSmoke'
            $result.Tasks.Error | Should -BeNullOrEmpty
        }
    }

    It 'throws when Invoke-Build does not return a result object' {
        InModuleScope Plumber {
            Mock Get-Command {
                {
                    'no result'
                }
            } -ParameterFilter {
                $Name -eq 'Invoke-Build'
            }

            $buildFile = Join-Path $TestDrive 'wrapper.build.ps1'
            {Invoke-PlumberBuild -Task MissingResult -BuildFile $BuildFile} |
                Should -Throw -ExpectedMessage 'Invoke-Build did not return a result object.'
        }
    }

    It 'returns the result object when Invoke-Build throws after writing the result variable' {
        InModuleScope Plumber {
            Mock Get-Command {
                {
                    param (
                        [string[]]
                        $Task,

                        [string]
                        $File,

                        [string]
                        $Result
                    )

                    $File | Should -Not -BeNullOrEmpty
                    Set-Variable -Name $Result -Scope 1 -Value ([pscustomobject]@{
                        Tasks = @(
                            [pscustomobject]@{
                                Name  = 'SetVariables'
                                Error = $null
                            }
                            [pscustomobject]@{
                                Name  = $Task[0]
                                Error = 'Task failed with full context'
                            }
                        )
                    })
                    throw 'One or more Plumber validation tasks failed: ModuleVersion'
                }
            } -ParameterFilter {
                $Name -eq 'Invoke-Build'
            }

            $buildFile = Join-Path $TestDrive 'wrapper.build.ps1'
            $result = Invoke-PlumberBuild -Task ModuleVersion -BuildFile $BuildFile

            $result.Tasks.Name | Should -Contain 'SetVariables'
            $result.Tasks.Name | Should -Contain 'ModuleVersion'
            $result.Tasks.Error | Should -Contain 'Task failed with full context'
        }
    }

    It 'streams raw output and returns result after Invoke-Build writes it then throws' {
        InModuleScope Plumber {
            Mock Out-Host {}
            Mock Get-Command {
                {
                    param (
                        [string[]]
                        $Task,

                        [string]
                        $File,

                        [string]
                        $Result
                    )

                    $File | Should -Not -BeNullOrEmpty
                    'raw failure output'
                    Set-Variable -Name $Result -Scope 1 -Value ([pscustomobject]@{
                        Tasks = @(
                            [pscustomobject]@{
                                Name  = $Task[0]
                                Error = 'Task failed with full context'
                            }
                        )
                    })
                    throw 'One or more Plumber validation tasks failed: ModuleVersion'
                }
            } -ParameterFilter {
                $Name -eq 'Invoke-Build'
            }

            $buildFile = Join-Path $TestDrive 'wrapper.build.ps1'
            $result = Invoke-PlumberBuild -Task ModuleVersion -BuildFile $BuildFile -RawOutput

            $result.Tasks.Name | Should -Contain 'ModuleVersion'
            $result.Tasks.Error | Should -Contain 'Task failed with full context'
            Should -Invoke Out-Host -Times 1 -Exactly
        }
    }

    It 'preserves Invoke-Build setup errors when no result object is available' {
        InModuleScope Plumber {
            Mock Get-Command {
                {
                    throw "File 'wrapper.build.ps1': Missing task 'NotARealTask'."
                }
            } -ParameterFilter {
                $Name -eq 'Invoke-Build'
            }

            $buildFile = Join-Path $TestDrive 'wrapper.build.ps1'
            {Invoke-PlumberBuild -Task NotARealTask -BuildFile $BuildFile} |
                Should -Throw -ExpectedMessage "*Missing task 'NotARealTask'*"
        }
    }

    It 'suppresses Invoke-Build output unless raw output is requested' {
        InModuleScope Plumber {
            Mock Out-Host {}
            Mock Get-Command {
                {
                    param (
                        [string[]]
                        $Task,

                        [string]
                        $File,

                        [string]
                        $Result
                    )

                    if (-not $File) {
                        throw 'Build file is required'
                    }

                    'suppressed output'
                    Set-Variable -Name $Result -Scope 1 -Value ([pscustomobject]@{
                        Tasks = @(
                            [pscustomobject]@{
                                Name  = $Task[0]
                                Error = $null
                            }
                        )
                    })
                }
            } -ParameterFilter {
                $Name -eq 'Invoke-Build'
            }

            $buildFile = Join-Path $TestDrive 'wrapper.build.ps1'
            $result = Invoke-PlumberBuild -Task QuietSmoke -BuildFile $BuildFile

            $result.Tasks.Name | Should -Contain 'QuietSmoke'
            Should -Invoke Out-Host -Times 0 -Exactly
        }
    }

    It 'disables Pester job output while suppressing build output' {
        InModuleScope Plumber {
            Mock Get-Command {
                {
                    param (
                        [string[]]
                        $Task,

                        [string]
                        $File,

                        [string]
                        $Result
                    )

                    $File | Should -Not -BeNullOrEmpty
                    Get-Variable -Name PlumberStreamPesterOutput -Scope Global -ValueOnly |
                        Should -BeFalse
                    Set-Variable -Name $Result -Scope 1 -Value ([pscustomobject]@{
                        Tasks = @(
                            [pscustomobject]@{
                                Name  = $Task[0]
                                Error = $null
                            }
                        )
                    })
                }
            } -ParameterFilter {
                $Name -eq 'Invoke-Build'
            }

            Set-Variable -Name PlumberStreamPesterOutput -Scope Global -Value 'previous'
            $buildFile = Join-Path $TestDrive 'wrapper.build.ps1'
            try {
                Invoke-PlumberBuild -Task QuietSmoke -BuildFile $BuildFile | Out-Null

                Get-Variable -Name PlumberStreamPesterOutput -Scope Global -ValueOnly |
                    Should -Be 'previous'
            } finally {
                Remove-Variable -Name PlumberStreamPesterOutput -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    It 'streams raw output without returning it as the build result' {
        InModuleScope Plumber {
            Mock Out-Host {}
            Mock Get-Command {
                {
                    param (
                        [string[]]
                        $Task,

                        [string]
                        $File,

                        [string]
                        $Result
                    )

                    if (-not $File) {
                        throw 'Build file is required'
                    }

                    'raw output'
                    Set-Variable -Name $Result -Scope 1 -Value ([pscustomobject]@{
                        Tasks = @(
                            [pscustomobject]@{
                                Name  = $Task[0]
                                Error = $null
                            }
                        )
                    })
                }
            } -ParameterFilter {
                $Name -eq 'Invoke-Build'
            }

            $buildFile = Join-Path $TestDrive 'wrapper.build.ps1'
            $result = Invoke-PlumberBuild -Task RawSmoke -BuildFile $BuildFile -RawOutput

            $result.Tasks.Name | Should -Contain 'RawSmoke'
            $result | Should -Not -Contain 'raw output'
            Should -Invoke Out-Host -Times 1 -Exactly
        }
    }

    It 'enables Pester job output while streaming raw output' {
        InModuleScope Plumber {
            Mock Out-Host {}
            Mock Get-Command {
                {
                    param (
                        [string[]]
                        $Task,

                        [string]
                        $File,

                        [string]
                        $Result
                    )

                    $File | Should -Not -BeNullOrEmpty
                    Get-Variable -Name PlumberStreamPesterOutput -Scope Global -ValueOnly |
                        Should -BeTrue
                    Set-Variable -Name $Result -Scope 1 -Value ([pscustomobject]@{
                        Tasks = @(
                            [pscustomobject]@{
                                Name  = $Task[0]
                                Error = $null
                            }
                        )
                    })
                }
            } -ParameterFilter {
                $Name -eq 'Invoke-Build'
            }

            Remove-Variable -Name PlumberStreamPesterOutput -Scope Global -ErrorAction SilentlyContinue
            $buildFile = Join-Path $TestDrive 'wrapper.build.ps1'
            Invoke-PlumberBuild -Task RawSmoke -BuildFile $BuildFile -RawOutput | Out-Null

            Get-Variable -Name PlumberStreamPesterOutput -Scope Global -ErrorAction SilentlyContinue |
                Should -BeNullOrEmpty
        }
    }
}

Describe 'Invoke-Plumber private wrapper recovery' {
    It 'reloads Invoke-PlumberBuild when module state loses the private function' {
        InModuleScope Plumber {
            Remove-Item Function:\Invoke-PlumberBuild -Force

            Mock Get-Command {
                {
                    param (
                        [string[]]
                        $Task,

                        [string]
                        $File,

                        [string]
                        $Result
                    )

                    if (-not $File) {
                        throw 'Build file is required'
                    }

                    Set-Variable -Name $Result -Scope 1 -Value ([pscustomobject]@{
                        Tasks = @(
                            [pscustomobject]@{
                                Name  = $Task[0]
                                Error = $null
                            }
                        )
                    })
                }
            } -ParameterFilter {
                $Name -eq 'Invoke-Build'
            }

            Invoke-Plumber -Task Content -OutputMode Table | Should -Match 'Content'
            Invoke-Plumber -Task JSON -OutputMode Table | Should -Match 'JSON'
        }
    }
}
