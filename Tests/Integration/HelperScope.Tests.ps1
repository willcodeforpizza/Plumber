BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }

    $script:invokeBuild = Get-Command Invoke-Build
}

Describe 'Private helpers are reachable from task scriptblocks without per-task dot-sources' {
    # Every helper a task scriptblock today defensively dot-sources. If this
    # test passes, the dot-source is redundant: TaskLoader already puts the
    # helper in the build-file scope and scriptblocks capture it via session
    # state.
    It 'sees <Helper> in a task scriptblock loaded via Tasks.Local' -ForEach @(
        @{ Helper = 'Get-PlumberTaskFile' }
        @{ Helper = 'Test-PlumberTaskPathExcluded' }
        @{ Helper = 'Get-PlumberChangedFile' }
        @{ Helper = 'Get-PlumberFunctionHelp' }
        @{ Helper = 'Test-PlumberFunctionHelp' }
        @{ Helper = 'Invoke-PlumberGit' }
        @{ Helper = 'ConvertTo-PlumberSemVer' }
        @{ Helper = 'Get-PlumberGitTagVersion' }
        @{ Helper = 'Get-PlumberTaskHelp' }
        @{ Helper = 'Get-PlumberTaskHelpSection' }
        @{ Helper = 'ConvertFrom-PlumberTaskHelpComment' }
        @{ Helper = 'ConvertTo-PlumberTaskHelpSection' }
        @{ Helper = 'ConvertTo-PlumberTaskMarkdown' }
        @{ Helper = 'ConvertTo-PlumberTaskMarkdownIndex' }
        @{ Helper = 'Add-PlumberTaskMarkdownSection' }
        @{ Helper = 'New-PlumberTaskMarkdown' }
    ) {
        $resultFile = Join-Path $TestDrive "$Helper.result"
        $taskFile = Join-Path $TestDrive "CheckScope-$Helper.ps1"
        @(
            "Add-BuildTask -Name CheckScope-$Helper -Jobs {"
            "    Set-Content -Path '$resultFile' -Value ("
            "        [bool] (Get-Command $Helper -ErrorAction SilentlyContinue)"
            "    )"
            '}'
        ) | Set-Content -Path $taskFile

        $manifestPath = Join-Path $TestDrive 'fixture.psd1'
        '@{ ModuleVersion = "0.0.1" }' | Set-Content -Path $manifestPath

        $buildFile = Join-Path $TestDrive "scope-$Helper.build.ps1"
        @(
            '. (Get-PlumberTaskLoader) -Config @{'
            "    ModuleManifest = 'fixture.psd1'"
            '    Tasks          = @{'
            "        Local = @('$taskFile')"
            '    }'
            '}'
        ) | Set-Content -Path $buildFile

        Push-Location $TestDrive
        try {
            & $script:invokeBuild -Task "CheckScope-$Helper" -File $buildFile
        } finally {
            Pop-Location
        }

        Test-Path $resultFile | Should -BeTrue -Because "task $Helper must have executed"
        (Get-Content $resultFile) | Should -Be 'True' -Because "$Helper must be in scope"
    }
}
