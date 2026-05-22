BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }

    function Get-TestConfigLeafPath {
        param (
            [Parameter(Mandatory)]
            [hashtable]
            $InputObject,

            [string]
            $Prefix
        )

        foreach ($key in $InputObject.Keys) {
            $path = if ($Prefix) { "$Prefix.$key" } else { $key }
            if ($InputObject[$key] -is [hashtable]) {
                Get-TestConfigLeafPath -InputObject $InputObject[$key] -Prefix $path
            } else {
                $path
            }
        }
    }
}

Describe 'Test-PlumberConfig' {
    It 'accepts the default merged config' {
        InModuleScope Plumber {
            $config = New-PlumberConfig

            { Test-PlumberConfig -Config $config } | Should -Not -Throw
        }
    }

    It 'has a validation rule for every default config leaf' {
        $config = InModuleScope Plumber { New-PlumberConfig }
        $rules = InModuleScope Plumber { Get-PlumberConfigRule }

        $leafPaths = Get-TestConfigLeafPath -InputObject $config
        foreach ($leafPath in $leafPaths) {
            $rules.ContainsKey($leafPath) | Should -BeTrue -Because "$leafPath needs a validation rule"
        }
    }

    It 'has validation rules that match default config leaves or known runtime keys' {
        $config = InModuleScope Plumber { New-PlumberConfig }
        $rules = InModuleScope Plumber { Get-PlumberConfigRule }
        $leafPaths = @(Get-TestConfigLeafPath -InputObject $config)
        $runtimePaths = @('BuildRoot')

        foreach ($rulePath in $rules.Keys) {
            $rulePath | Should -BeIn ($leafPaths + $runtimePaths)
        }
    }

    It 'reports an unknown task once and skips child settings below it' {
        InModuleScope Plumber {
            $config = New-PlumberConfig -Config @{
                Tasks = @{
                    LiiiineLength = @{
                        MaxLength = 123
                    }
                }
            }

            { Test-PlumberConfig -Config $config } |
                Should -Throw -ExpectedMessage @(
                    '*Tasks.LiiiineLength is not a known task*'
                    '*Did you mean LineLength?*'
                )
        }
    }

    It 'suggests configured local task names for unknown local task typos' {
        InModuleScope Plumber {
            $config = New-PlumberConfig -Config @{
                Tasks = @{
                    Local     = @('LocalTasks/BuildDocs.ps1')
                    BuildDocz = @{
                        Whatever = 123
                    }
                }
            }

            { Test-PlumberConfig -Config $config } |
                Should -Throw -ExpectedMessage @(
                    '*Tasks.BuildDocz is not a known task*'
                    '*Did you mean BuildDocs?*'
                )
        }
    }

    It 'reports an unknown setting with a suggestion' {
        InModuleScope Plumber {
            $config = New-PlumberConfig -Config @{
                Tasks = @{
                    PSScriptAnalyzer = @{
                        Excdddlude = @('Tests/*')
                    }
                }
            }

            { Test-PlumberConfig -Config $config } |
                Should -Throw -ExpectedMessage @(
                    '*Tasks.PSScriptAnalyzer.Excdddlude is not a known setting*'
                    '*Did you mean Exclude?*'
                )
        }
    }

    It 'reports invalid top-level value types' {
        InModuleScope Plumber {
            $config = New-PlumberConfig -Config @{
                IncludeModuleFolders = 'TaskFunctions'
                ModuleManifest       = 123
            }

            try {
                Test-PlumberConfig -Config $config
            } catch {
                $message = $_.Exception.Message
            }

            $message | Should -Match 'IncludeModuleFolders: Expected string array, got String'
            $message | Should -Match 'ModuleManifest: Expected string, got Int32'
        }
    }

    It 'reports task config blocks that are not hashtables' {
        InModuleScope Plumber {
            $config = New-PlumberConfig -Config @{
                Tasks = @{
                    LineLength = 'fast'
                }
            }

            { Test-PlumberConfig -Config $config } |
                Should -Throw -ExpectedMessage '*Tasks.LineLength: Expected hashtable*'
        }
    }

    It 'aggregates unknown keys and invalid values' {
        InModuleScope Plumber {
            $config = New-PlumberConfig -Config @{
                Unexpected = $true
                FileScope  = 'Sometimes'
                Tasks      = @{
                    LineLength = @{
                        MaxLenght = 80
                        MaxLength = 10001
                    }
                }
            }

            try {
                Test-PlumberConfig -Config $config
            } catch {
                $message = $_.Exception.Message
            }

            $message | Should -Match 'Unexpected is not a known top-level key'
            $message | Should -Match 'FileScope: Expected one of'
            $message | Should -Match 'Tasks.LineLength.MaxLength: Expected at most 10000, got 10001'
            $message | Should -Match 'Tasks.LineLength.MaxLenght is not a known setting'
        }
    }

    It 'rejects numeric strings instead of coercing them' {
        InModuleScope Plumber {
            $config = New-PlumberConfig -Config @{
                Tasks = @{
                    CodeCoverage = @{
                        Minimum = '75'
                    }
                }
            }

            { Test-PlumberConfig -Config $config } |
                Should -Throw -ExpectedMessage @(
                    '*Tasks.CodeCoverage.Minimum: Expected integer, got String*'
                )
        }
    }

    It 'rejects invalid collection item types' {
        InModuleScope Plumber {
            $config = New-PlumberConfig -Config @{
                Tasks = @{
                    Local = @('LocalTasks/BuildDocs.ps1', 123)
                }
            }

            { Test-PlumberConfig -Config $config } |
                Should -Throw -ExpectedMessage '*Tasks.Local: Expected string array, got item of type Int32*'
        }
    }

    It 'rejects invalid JSONSchema schema collection types' {
        InModuleScope Plumber {
            $config = New-PlumberConfig -Config @{
                Tasks = @{
                    JSONSchema = @{
                        Schemas = 'Resource/schema.json'
                    }
                }
            }

            { Test-PlumberConfig -Config $config } |
                Should -Throw -ExpectedMessage '*Tasks.JSONSchema.Schemas: Expected array, got String*'
        }
    }

    It 'rejects invalid JSONSchema schema mappings' {
        InModuleScope Plumber {
            $config = New-PlumberConfig -Config @{
                Tasks = @{
                    JSONSchema = @{
                        Schemas = @(
                            @{
                                Path = 'Resource/*.json'
                            }
                        )
                    }
                }
            }

            { Test-PlumberConfig -Config $config } |
                Should -Throw -ExpectedMessage '*Tasks.JSONSchema.Schemas: Expected item 0 to include Schema*'
        }
    }

    It 'allows configured local task names with unchecked bodies' {
        InModuleScope Plumber {
            $config = New-PlumberConfig -Config @{
                Tasks = @{
                    Local     = @('LocalTasks/BuildDocs.ps1')
                    BuildDocs = @{
                        Whatever = 123
                    }
                }
            }

            { Test-PlumberConfig -Config $config } | Should -Not -Throw
        }
    }
}
