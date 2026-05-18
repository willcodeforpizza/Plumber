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

    It 'does not load Content when all Content child tasks are excluded' {
        $buildFile = Join-Path $TestDrive 'skip-all-content.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            "    Tasks = @{ Exclude = @('JSON', 'JSONSchema', 'YAML') }"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Not -Contain 'Content'
        $tasks['Validate'].Jobs | Should -Not -Contain '?Content'
    }

    It 'does not load Content children when Content is excluded' {
        $buildFile = Join-Path $TestDrive 'skip-content-parent.build.ps1'
        @(
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'Plumber.psd1'"
            "    Tasks = @{ Exclude = @('Content') }"
            '}'
        ) | Set-Content -Path $buildFile

        $tasks = & $script:invokeBuild -Task '??' -File $buildFile
        $tasks.Keys | Should -Not -Contain 'Content'
        $tasks.Keys | Should -Not -Contain 'JSON'
        $tasks.Keys | Should -Not -Contain 'JSONSchema'
        $tasks.Keys | Should -Not -Contain 'YAML'
        $tasks['Validate'].Jobs | Should -Not -Contain '?Content'
    }

}
