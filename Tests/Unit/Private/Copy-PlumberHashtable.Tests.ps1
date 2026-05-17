BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Copy-PlumberHashtable' {
    It 'returns a shallow-equal but independent hashtable for scalar values' {
        InModuleScope Plumber {
            $original = @{ Name = 'foo'; Count = 3; Enabled = $true }
            $copy = Copy-PlumberHashtable -InputObject $original
            $copy['Name'] | Should -Be 'foo'
            $copy['Count'] | Should -Be 3
            $copy['Enabled'] | Should -BeTrue
            $copy['Name'] = 'bar'
            $original['Name'] | Should -Be 'foo'
        }
    }

    It 'deep-clones nested hashtables' {
        InModuleScope Plumber {
            $original = @{ Tasks = @{ Exclude = @('a', 'b') } }
            $copy = Copy-PlumberHashtable -InputObject $original
            $copy.Tasks.Exclude += 'c'
            $original.Tasks.Exclude.Count | Should -Be 2
            $copy.Tasks.Exclude.Count | Should -Be 3
        }
    }

    It 'deep-clones hashtables inside arrays' {
        InModuleScope Plumber {
            $original = @{
                Schemas = @(
                    @{ Path = 'A'; Schema = 'A.schema' }
                    @{ Path = 'B'; Schema = 'B.schema' }
                )
            }
            $copy = Copy-PlumberHashtable -InputObject $original
            $copy.Schemas[0].Path = 'MUTATED'
            $original.Schemas[0].Path | Should -Be 'A'
        }
    }

    It 'preserves empty arrays as arrays not $null' {
        InModuleScope Plumber {
            $original = @{ Exclude = @() }
            $copy = Copy-PlumberHashtable -InputObject $original
            # The pipeline unwraps single-element arrays, so test via reflection.
            $copy.Exclude.GetType().IsArray | Should -BeTrue
            $copy.Exclude.Count | Should -Be 0
        }
    }

    It 'preserves $null values' {
        InModuleScope Plumber {
            $original = @{ ModuleManifest = $null }
            $copy = Copy-PlumberHashtable -InputObject $original
            $copy.ContainsKey('ModuleManifest') | Should -BeTrue
            $copy['ModuleManifest'] | Should -BeNullOrEmpty
        }
    }

    It 'handles mixed nested structure typical of Plumber config' {
        InModuleScope Plumber {
            $original = @{
                ModuleManifest = 'MyModule.psd1'
                FileScope      = 'All'
                Tasks          = @{
                    Exclude    = @('YAML')
                    LineLength = @{ MaxLength = 80; Exclude = @() }
                    JSONSchema = @{
                        Schemas = @(@{ Path = 'X'; Schema = 'Y' })
                    }
                }
            }
            $copy = Copy-PlumberHashtable -InputObject $original
            $copy.Tasks.LineLength.MaxLength = 120
            $copy.Tasks.JSONSchema.Schemas[0].Path = 'CHANGED'
            $copy.Tasks.Exclude += 'JSON'
            $original.Tasks.LineLength.MaxLength | Should -Be 80
            $original.Tasks.JSONSchema.Schemas[0].Path | Should -Be 'X'
            $original.Tasks.Exclude | Should -Be @('YAML')
        }
    }
}
