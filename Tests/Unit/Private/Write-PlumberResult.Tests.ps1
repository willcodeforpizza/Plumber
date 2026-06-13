BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Write-PlumberResult' {
    BeforeAll {
        function Get-TestPlumberResult {
            param (
                [switch]
                $Failed
            )

            $tasks = @(
                [pscustomobject]@{
                    Name   = 'SetVariables'
                    Status = 'Passed'
                    Error  = $null
                }
            )

            if ($Failed) {
                $tasks += [pscustomobject]@{
                    Name   = 'ToDo'
                    Status = 'Failed'
                    Error  = 'Found TODO in Public/Get-Thing.ps1'
                }
            }

            $failures = @($tasks | Where-Object Status -EQ 'Failed')
            [pscustomobject]@{
                Success  = $failures.Count -eq 0
                Passed   = @($tasks | Where-Object Status -EQ 'Passed').Count
                Failed   = $failures.Count
                Tasks    = $tasks
                Failures = $failures
            }
        }
    }

    It 'writes plain success summary when formatting is disabled' {
        $result = Get-TestPlumberResult
        InModuleScope Plumber -Parameters @{ Result = $result } {
            param ($Result)

            $output = Write-PlumberResult -Result $Result -OutputMode Summary -NoFormat

            $output | Should -Be 'Plumber validation passed. Passed: 1. Failed: 0.'
            $output | Should -Not -Match ([regex]::Escape("$([char]27)["))
        }
    }

    It 'writes formatted success summary by default' {
        $result = Get-TestPlumberResult
        InModuleScope Plumber -Parameters @{ Result = $result } {
            param ($Result)

            $output = Write-PlumberResult -Result $Result -OutputMode Summary
            $outputText = $output | Out-String

            $outputText |
                Should -Match ([regex]::Escape("$([char]27)[32mPlumber validation passed."))
            $outputText |
                Should -Match ([regex]::Escape("$([char]27)[32mPassed: 1.$([char]27)[0m"))
            $outputText | Should -Match 'Failed: 0.'
        }
    }

    It 'writes failure summary with task details and counts' {
        $result = Get-TestPlumberResult -Failed
        InModuleScope Plumber -Parameters @{ Result = $result } {
            param ($Result)

            $output = Write-PlumberResult -Result $Result -OutputMode Summary -NoFormat

            $output[0] | Should -Be ''
            $output | Should -Contain 'Plumber validation failed.'
            $output | Should -Contain 'ToDo:'
            $output | Should -Contain 'Found TODO in Public/Get-Thing.ps1'
            $output | Should -Contain 'Passed: 1. Failed: 1.'
        }
    }

    It 'writes structured JSON output' {
        $result = Get-TestPlumberResult -Failed
        InModuleScope Plumber -Parameters @{ Result = $result } {
            param ($Result)

            $jsonText = Write-PlumberResult -Result $Result -OutputMode Json
            $json = $jsonText | ConvertFrom-Json

            $json.Success | Should -BeFalse
            $json.Passed | Should -Be 1
            $json.Failed | Should -Be 1
            $json.Tasks[1].Name | Should -Be 'ToDo'
            $json.Tasks[1].Status | Should -Be 'Failed'
            $json.Failures[0].Error | Should -Be 'Found TODO in Public/Get-Thing.ps1'
        }
    }

    It 'writes table rows and failure details without ANSI when formatting is disabled' {
        $result = Get-TestPlumberResult -Failed
        InModuleScope Plumber -Parameters @{ Result = $result } {
            param ($Result)

            $output = Write-PlumberResult -Result $Result -OutputMode Table -NoFormat
            $outputText = $output | Out-String

            $outputText | Should -Match 'SetVariables\s+Passed'
            $outputText | Should -Match 'ToDo\s+Failed'
            $output | Should -Contain 'ToDo:'
            $output | Should -Contain 'Found TODO in Public/Get-Thing.ps1'
            $outputText | Should -Not -Match ([regex]::Escape("$([char]27)["))
        }
    }

    It 'writes raw mode through the same result table formatter' {
        $result = Get-TestPlumberResult -Failed
        InModuleScope Plumber -Parameters @{ Result = $result } {
            param ($Result)

            $output = Write-PlumberResult -Result $Result -OutputMode Raw -NoFormat
            $outputText = $output | Out-String

            $outputText | Should -Match 'SetVariables\s+Passed'
            $outputText | Should -Match 'ToDo\s+Failed'
            $output | Should -Contain 'Found TODO in Public/Get-Thing.ps1'
        }
    }

    It 'writes CI mode as concise summary output' {
        $result = Get-TestPlumberResult
        InModuleScope Plumber -Parameters @{ Result = $result } {
            param ($Result)

            $output = Write-PlumberResult -Result $Result -OutputMode CI -NoFormat

            $output | Should -Be 'Plumber validation passed. Passed: 1. Failed: 0.'
        }
    }
}
