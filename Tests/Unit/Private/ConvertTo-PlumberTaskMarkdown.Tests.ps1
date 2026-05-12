BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'ConvertTo-PlumberTaskMarkdown' {
    It 'writes group task Markdown' {
        InModuleScope Plumber {
            $help = [pscustomobject]@{
                Name          = 'Content'
                Synopsis      = 'Runs content validation tasks.'
                Description   = 'Runs content validation.'
                Group         = $null
                Includes      = @('JSON', 'YAML')
                Configuration = $null
                Run           = @'
```powershell
Invoke-Plumber -Task Content
```
'@
                Pass          = $null
                Fail          = $null
            }
            $allHelp = @(
                [pscustomobject]@{Name = 'CodeQuality'; Group = $null; Includes = @('Backticks')}
                $help
                [pscustomobject]@{Name = 'ModuleConventions'; Group = $null; Includes = @('Help')}
            )

            $markdown = ConvertTo-PlumberTaskMarkdown -Help $help -AllHelp $allHelp

            $markdown | Should -Match '# Content'
            $markdown | Should -Match '## Includes'
            $markdown | Should -Match '- `JSON`'
            $markdown | Should -Match 'Invoke-Plumber -Task Content'
            $markdown | Should -Match '## Navigation'
            $markdown | Should -Match '\[Task index\]\(index\.md\)'
            $markdown | Should -Match 'Previous: \[CodeQuality\]\(CodeQuality\.md\)'
            $markdown | Should -Match 'Next: \[ModuleConventions\]\(ModuleConventions\.md\)'
            $markdown | Should -Not -Match '## Pass'
            $markdown | Should -Not -Match '## Fail'
        }
    }

    It 'writes leaf task Markdown' {
        InModuleScope Plumber {
            $help = [pscustomobject]@{
                Name          = 'YAML'
                Synopsis      = 'Validates YAML files.'
                Description   = 'Checks YAML syntax.'
                Group         = 'Content'
                Includes      = @()
                Configuration = 'None.'
                Run           = @'
```powershell
Invoke-Plumber -Task YAML
```
'@
                Pass          = @'
```yaml
name: build
```
'@
                Fail          = @'
```yaml
name: build:
```
'@
            }
            $allHelp = @(
                [pscustomobject]@{Name = 'JSON'; Group = 'Content'; Includes = @()}
                $help
                [pscustomobject]@{Name = 'JSONSchema'; Group = 'Content'; Includes = @()}
            )

            $markdown = ConvertTo-PlumberTaskMarkdown -Help $help -AllHelp $allHelp

            $markdown | Should -Match '# YAML'
            $markdown | Should -Match '## Group'
            $markdown | Should -Match 'Content'
            $markdown | Should -Match '## Pass'
            $markdown | Should -Match '```yaml'
            $markdown | Should -Match '## Fail'
            $markdown | Should -Match '\[Group: Content\]\(Content\.md\)'
            $markdown | Should -Match 'Previous: \[JSONSchema\]\(JSONSchema\.md\)'
            $markdown | Should -Not -Match 'Next:'
        }
    }
}
