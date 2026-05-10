BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'New-PlumberTaskMarkdown' {
    It 'writes Markdown files for documented tasks' {
        $taskRoot = Join-Path $TestDrive 'Tasks'
        $outputRoot = Join-Path $TestDrive 'docs/tasks'
        New-Item -Path (Join-Path $taskRoot 'Content') -ItemType Directory | Out-Null
        $contentSource = Join-Path $PSScriptRoot '../Assets/TaskHelp/Content.ps1'
        $yamlSource = Join-Path $PSScriptRoot '../Assets/TaskHelp/YAML.ps1'
        Copy-Item -Path $contentSource -Destination (Join-Path $taskRoot 'Content/Content.ps1')
        Copy-Item -Path $yamlSource -Destination (Join-Path $taskRoot 'Content/YAML.ps1')
        Set-Content -Path (Join-Path $taskRoot 'Content/NoHelp.ps1') -Value 'Add-BuildTask -Name NoHelp -Jobs {}'

        InModuleScope Plumber -Parameters @{
            TaskRoot = $taskRoot
            OutputRoot = $outputRoot
        } {
            New-PlumberTaskMarkdown -TaskRoot $TaskRoot -OutputRoot $OutputRoot
        }

        Test-Path (Join-Path $outputRoot 'Content.md') | Should -BeTrue
        Test-Path (Join-Path $outputRoot 'YAML.md') | Should -BeTrue
        Test-Path (Join-Path $outputRoot 'NoHelp.md') | Should -BeFalse
        Test-Path (Join-Path $outputRoot 'index.md') | Should -BeTrue

        Get-Content (Join-Path $outputRoot 'YAML.md') -Raw |
            Should -Match 'Invoke-Plumber -Task YAML'

        Get-Content (Join-Path $outputRoot 'YAML.md') -Raw |
            Should -Match '\[Group: Content\]\(Content\.md\)'

        $index = Get-Content (Join-Path $outputRoot 'index.md') -Raw
        $index | Should -Match '## Groups'
        $index | Should -Match '\| \[Content\]\(Content\.md\) \| `JSON`, `JSONSchema`, `YAML` \|'
        $index | Should -Match '## Tasks'
        $index | Should -Match '\| \[YAML\]\(YAML\.md\) \| `Content` \|'
    }
}
