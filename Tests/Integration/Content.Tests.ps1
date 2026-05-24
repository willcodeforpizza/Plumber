BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberTaskLoader content integration' {
    BeforeAll {
        $script:invokeBuild = Get-Command Invoke-Build
    }

    It 'loads JSONSchema directly under Content' {
        $buildFile = Join-Path $TestDrive 'content.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'JSONSchema'
        $tasks['Content'].Jobs | Should -Contain '?JSONSchema'
    }

    It 'loads Content with skipped children when all Content child tasks use RunWhen Never' {
        $buildFile = Join-Path $TestDrive 'skip-all-content.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            '    Tasks = @{'
            "        JSON = @{ RunWhen = 'Never' }"
            "        JSONSchema = @{ RunWhen = 'Never' }"
            "        YAML = @{ RunWhen = 'Never' }"
            '    }'
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'Content'
        $tasks.Keys | Should -Contain 'JSON'
        $tasks.Keys | Should -Contain 'JSONSchema'
        $tasks.Keys | Should -Contain 'YAML'
        $tasks['Validate'].Jobs | Should -Contain '?Content'
    }

    It 'registers Content as skipped without loading children when Content uses RunWhen Never' {
        $buildFile = Join-Path $TestDrive 'skip-content-group.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            '    Tasks = @{'
            "        Content = @{ RunWhen = 'Never' }"
            '    }'
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Contain 'Content'
        $tasks.Keys | Should -Not -Contain 'JSON'
        $tasks.Keys | Should -Not -Contain 'JSONSchema'
        $tasks.Keys | Should -Not -Contain 'YAML'
        $tasks['Validate'].Jobs | Should -Contain '?Content'
    }

    It 'rejects removed Content group exclusion config' {
        $buildFile = Join-Path $TestDrive 'skip-content-parent.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            "    Tasks = @{ Exclude = @('Content') }"
            '}'
        ) | Set-Content -Path $buildFile

        { & $script:invokeBuild -Task '??' -File $buildFile } |
            Should -Throw -ExpectedMessage '*Tasks.Exclude is not a known task*'
    }

}
