BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberConfigRule' {
    It 'returns the expected top-level rules' {
        InModuleScope Plumber {
            $rules = Get-PlumberConfigRule

            $rules.ModuleManifest.Validate | Should -Be 'string'
            $rules.ModuleManifest.Nullable | Should -BeTrue
            $rules.FileScope.Validate | Should -Be 'enum'
            $rules.FileScope.Values | Should -Be @('All', 'Changed')
            $rules.IncludeModuleFolders.Validate | Should -Be 'string-array'
            $rules.BuildRoot.Validate | Should -Be 'string'
        }
    }

    It 'returns the expected task setting rules' {
        InModuleScope Plumber {
            $rules = Get-PlumberConfigRule

            $rules['Tasks.LineLength.MaxLength'].Validate | Should -Be 'integer'
            $rules['Tasks.LineLength.MaxLength'].Min | Should -Be 1
            $rules['Tasks.LineLength.MaxLength'].Max | Should -Be 10000
            $rules['Tasks.CodeCoverage.Minimum'].Min | Should -Be 0
            $rules['Tasks.CodeCoverage.Minimum'].Max | Should -Be 100
            $rules['Tasks.PSScriptAnalyzer.Exclude'].Validate | Should -Be 'string-array'
            $rules['Tasks.JSONSchema.Schemas'].Validate | Should -Be 'object-array'
            $rules['Tasks.JSONSchema.Schemas'].ItemRule.Path.Validate | Should -Be 'string'
            $rules['Tasks.JSONSchema.Schemas'].ItemRule.Schema.Validate | Should -Be 'string'
            $rules['Tasks.ModuleVersion.Source'].Values | Should -Be @('PSGallery', 'GitTag')
        }
    }

    It 'assigns a named validator to every rule' {
        InModuleScope Plumber {
            foreach ($rule in (Get-PlumberConfigRule).Values) {
                $rule.Validate | Should -Not -BeNullOrEmpty
            }
        }
    }
}
