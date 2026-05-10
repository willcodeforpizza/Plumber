BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
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

            $markdown = ConvertTo-PlumberTaskMarkdown -Help $help

            $markdown | Should -Match '# Content'
            $markdown | Should -Match '## Includes'
            $markdown | Should -Match '- `JSON`'
            $markdown | Should -Match 'Invoke-Plumber -Task Content'
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

            $markdown = ConvertTo-PlumberTaskMarkdown -Help $help

            $markdown | Should -Match '# YAML'
            $markdown | Should -Match '## Group'
            $markdown | Should -Match 'Content'
            $markdown | Should -Match '## Pass'
            $markdown | Should -Match '```yaml'
            $markdown | Should -Match '## Fail'
        }
    }
}
