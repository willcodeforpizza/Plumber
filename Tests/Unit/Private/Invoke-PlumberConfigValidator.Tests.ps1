BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberConfigValidator' {
    It 'accepts nullable null values' {
        InModuleScope Plumber {
            $rule = @{Validate = 'string'; Nullable = $true}

            Invoke-PlumberConfigValidator -Value $null -Rule $rule | Should -BeNullOrEmpty
        }
    }

    It 'rejects non-nullable null values' {
        InModuleScope Plumber {
            $rule = @{Validate = 'string'}

            Invoke-PlumberConfigValidator -Value $null -Rule $rule |
                Should -Be 'Expected value, got null'
        }
    }

    It 'accepts valid validator values' {
        InModuleScope Plumber {
            $cases = @(
                @{Value = $true; Rule = @{Validate = 'boolean'}}
                @{Value = 80; Rule = @{Validate = 'integer'; Min = 1; Max = 100}}
                @{Value = @(@{Path = 'a.json'}); Rule = @{Validate = 'object-array'}}
                @{Value = 'module.psd1'; Rule = @{Validate = 'string'}}
                @{Value = @('Public', 'Private'); Rule = @{Validate = 'string-array'}}
                @{Value = 'Changed'; Rule = @{Validate = 'enum'; Values = @('All', 'Changed')}}
            )

            foreach ($case in $cases) {
                Invoke-PlumberConfigValidator -Value $case.Value -Rule $case.Rule |
                    Should -BeNullOrEmpty
            }
        }
    }

    It 'rejects invalid validator values with friendly messages' {
        InModuleScope Plumber {
            $cases = @(
                @{
                    Value   = 'true'
                    Rule    = @{Validate = 'boolean'}
                    Message = 'Expected boolean, got String'
                }
                @{
                    Value   = 0
                    Rule    = @{Validate = 'integer'; Min = 1}
                    Message = 'Expected at least 1, got 0'
                }
                @{
                    Value   = 101
                    Rule    = @{Validate = 'integer'; Max = 100}
                    Message = 'Expected at most 100, got 101'
                }
                @{
                    Value   = 'schema'
                    Rule    = @{Validate = 'object-array'}
                    Message = 'Expected array, got String'
                }
                @{
                    Value   = 123
                    Rule    = @{Validate = 'string'}
                    Message = 'Expected string, got Int32'
                }
                @{
                    Value   = 'Public'
                    Rule    = @{Validate = 'string-array'}
                    Message = 'Expected string array, got String'
                }
                @{
                    Value   = @('Public', 123)
                    Rule    = @{Validate = 'string-array'}
                    Message = 'Expected string array, got item of type Int32'
                }
                @{
                    Value   = @('schema')
                    Rule    = @{Validate = 'object-array'; ItemRule = @{Path = @{Validate = 'string'}}}
                    Message = 'Expected item 0 to be hashtable, got String'
                }
                @{
                    Value   = @(@{Schema = 'Resource/schema.json'})
                    Rule    = @{Validate = 'object-array'; ItemRule = @{Path = @{Validate = 'string'}}}
                    Message = 'Expected item 0 to include Path'
                }
                @{
                    Value   = @(@{Path = 123})
                    Rule    = @{Validate = 'object-array'; ItemRule = @{Path = @{Validate = 'string'}}}
                    Message = 'Item 0.Path: Expected string, got Int32'
                }
                @{
                    Value   = 'Sometimes'
                    Rule    = @{Validate = 'enum'; Values = @('All', 'Changed')}
                    Message = "Expected one of 'All', 'Changed', got 'Sometimes'"
                }
            )

            foreach ($case in $cases) {
                Invoke-PlumberConfigValidator -Value $case.Value -Rule $case.Rule |
                    Should -Be $case.Message
            }
        }
    }
}
