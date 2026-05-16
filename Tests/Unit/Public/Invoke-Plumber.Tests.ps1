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

    It 'writes ANSI formatting by default' {
        InModuleScope Plumber {
            $escape = [regex]::Escape("$([char]27)[32mPlumber validation passed.")

            Invoke-Plumber |
                Out-String |
                    Should -Match $escape
        }
    }

    It 'writes plain text when formatting is disabled' {
        InModuleScope Plumber {
            $output = Invoke-Plumber -NoFormat

            $output | Should -Contain 'Plumber validation passed. Passed: 1. Failed: 0.'
            $output | Out-String | Should -Not -Match ([regex]::Escape("$([char]27)["))
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
            Invoke-Plumber -Task local -OutputMode Raw |
                Out-String |
                    Should -Match 'Validate'

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
                Invoke-Plumber -Task Validate -NoFormat
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }

            $output | Should -Contain 'Plumber validation failed.'
            $output | Should -Contain 'ModuleVersion:'
            $output | Should -Contain $longError
            $output | Should -Contain 'Passed: 1. Failed: 1.'
        }
    }

    It 'formats failure summaries with spacing and neutral task headings by default' {
        InModuleScope Plumber {
            $errorText = 'PSD1 version might be out of date.'
            $script:mockBuildResult = [pscustomobject]@{
                Tasks = @(
                    [pscustomobject]@{
                        Name  = 'ModuleVersion'
                        Error = $errorText
                    }
                )
            }

            $output = try {
                Invoke-Plumber -Task Validate
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }
            $outputText = $output | Out-String

            $output[0] | Should -Be ''
            $outputText |
                Should -Match ([regex]::Escape("$([char]27)[1;90mPlumber validation failed."))
            $outputText |
                Should -Match ([regex]::Escape("$([char]27)[90mModuleVersion:$([char]27)[0m"))
            $outputText |
                Should -Match ([regex]::Escape("$([char]27)[31m$errorText$([char]27)[0m"))
            $outputText |
                Should -Match ([regex]::Escape("$([char]27)[32mPassed: 0.$([char]27)[0m"))
            $outputText |
                Should -Match ([regex]::Escape("$([char]27)[31mFailed: 1.$([char]27)[0m"))
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

    It 'writes visible task rows in table mode' {
        InModuleScope Plumber {
            Invoke-Plumber -OutputMode Table |
                Out-String |
                    Should -Match 'Validate'
        }
    }

    It 'hides group failures when child task failures explain them' {
        InModuleScope Plumber {
            $analyzerError = @(
                'Get-Bad.ps1:3 - PSAvoidUsingWriteHost - File contains Write-Host.'
                'Detailed analyzer text: 1234567890abcdefghijklmnopqrstuvwxyz'
            ) -join [Environment]::NewLine
            $script:mockBuildResult = [pscustomobject]@{
                Tasks = @(
                    [pscustomobject]@{
                        Name  = 'SetVariables'
                        Error = $null
                    }
                    [pscustomobject]@{
                        Name  = 'PSScriptAnalyzer'
                        Error = $analyzerError
                    }
                    [pscustomobject]@{
                        Name  = 'CodeQuality'
                        Error = 'One or more CodeQuality tasks failed: PSScriptAnalyzer'
                        Jobs  = @('?PSScriptAnalyzer')
                    }
                    [pscustomobject]@{
                        Name  = 'Validate'
                        Error = 'One or more Plumber validation tasks failed: CodeQuality'
                        Jobs  = @('?CodeQuality')
                    }
                )
            }

            $summary = try {
                Invoke-Plumber -Task Validate -NoFormat
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }

            $summary | Should -Contain 'PSScriptAnalyzer:'
            $summary | Should -Contain $analyzerError
            $summary | Should -Not -Contain 'CodeQuality:'
            $summary | Should -Not -Contain 'Validate:'

            $table = try {
                Invoke-Plumber -Task Validate -OutputMode Table -NoFormat
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }
            $tableText = $table | Out-String

            $tableText | Should -Match 'PSScriptAnalyzer\s+Failed'
            $table | Should -Contain $analyzerError
            $tableText | Should -Not -Match 'CodeQuality\s+Failed'
            $tableText | Should -Not -Match 'Validate\s+Failed'

            $jsonText = try {
                Invoke-Plumber -Task Validate -OutputMode Json
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }
            $json = $jsonText | ConvertFrom-Json

            $json.Tasks.Name | Should -Contain 'PSScriptAnalyzer'
            $json.Tasks.Name | Should -Not -Contain 'CodeQuality'
            $json.Tasks.Name | Should -Not -Contain 'Validate'
            $json.Tasks |
                Where-Object Name -eq 'PSScriptAnalyzer' |
                    Select-Object -ExpandProperty Error |
                        Should -Be $analyzerError
            $json.Failures[0].Error | Should -Be $analyzerError
        }
    }

    It 'preserves a group failure when no child task failure explains it' {
        InModuleScope Plumber {
            $groupError = 'Setup failed before any child validation task could run.'
            $script:mockBuildResult = [pscustomobject]@{
                Tasks = @(
                    [pscustomobject]@{
                        Name  = 'Validate'
                        Error = $groupError
                    }
                )
            }

            $summary = try {
                Invoke-Plumber -Task Validate -NoFormat
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }

            $summary | Should -Contain 'Validate:'
            $summary | Should -Contain $groupError

            $table = try {
                Invoke-Plumber -Task Validate -OutputMode Table -NoFormat
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }
            $tableText = $table | Out-String

            $tableText | Should -Match 'Validate\s+Failed'
            $table | Should -Contain $groupError

            $jsonText = try {
                Invoke-Plumber -Task Validate -OutputMode Json
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }
            $json = $jsonText | ConvertFrom-Json

            $json.Tasks[0].Name | Should -Be 'Validate'
            $json.Tasks[0].Error | Should -Be $groupError
            $json.Failures[0].Error | Should -Be $groupError
        }
    }

    It 'colors table failure status and details by default' {
        InModuleScope Plumber {
            $errorText = 'Found TODO'
            $script:mockBuildResult = [pscustomobject]@{
                Tasks = @(
                    [pscustomobject]@{
                        Name  = 'ToDo'
                        Error = $errorText
                    }
                )
            }

            $output = try {
                Invoke-Plumber -Task ToDo -OutputMode Table
            } catch {
                $PSItem.Exception.Message | Should -Be 'Build failed!'
            }
            $outputText = $output | Out-String

            $outputText | Should -Match ([regex]::Escape("$([char]27)[31mFailed$([char]27)[0m"))
            $outputText | Should -Match ([regex]::Escape("$([char]27)[90mToDo:$([char]27)[0m"))
            $outputText | Should -Match ([regex]::Escape("$([char]27)[31m$errorText$([char]27)[0m"))
        }
    }

    It 'requests raw build output in raw mode' {
        InModuleScope Plumber {
            Invoke-Plumber -OutputMode Raw |
                Out-String |
                    Should -Match 'Validate'

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

            Invoke-Plumber -Task Content -OutputMode Table |
                Out-String |
                    Should -Match 'Content'
            Invoke-Plumber -Task JSON -OutputMode Table |
                Out-String |
                    Should -Match 'JSON'
        }
    }
}
