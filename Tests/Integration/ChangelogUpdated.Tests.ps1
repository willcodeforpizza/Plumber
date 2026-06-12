BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }

    # Runs the ChangelogUpdated task through a real Invoke-Plumber build in a
    # fresh pwsh process. Invoke-Build runs with ErrorActionPreference Stop,
    # so error-path behaviour must be asserted at this level, not only on the
    # task function.
    function Invoke-ChangelogTaskRun {
        param (
            [string]
            $ModuleRoot
        )

        $modulePath = (Resolve-Path "$PSScriptRoot/../../Plumber.psd1").Path.Replace("'", "''")
        $moduleRootLiteral = $ModuleRoot.Replace("'", "''")
        $command = @"
Import-Module '$modulePath' -Force
Push-Location '$moduleRootLiteral'
Invoke-Plumber -Task ChangelogUpdated -OutputMode Summary -NoFormat
"@

        $output = & (Get-Command pwsh).Source -NoLogo -NoProfile -Command $command 2>&1 |
            Out-String

        [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = $output
        }
    }

    function New-ChangelogFixtureModule {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseShouldProcessForStateChangingFunctions',
            '',
            Justification = 'Creates throwaway TestDrive fixtures only.'
        )]
        [CmdletBinding()]
        param (
            [string]
            $Name,

            [string[]]
            $ManifestLines,

            [string[]]
            $ChangelogLines
        )

        $moduleRoot = Join-Path $TestDrive $Name
        Remove-Item -Path $moduleRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $moduleRoot -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $moduleRoot "$Name.psd1") -Value $ManifestLines
        Set-Content -Path (Join-Path $moduleRoot 'CHANGELOG.md') -Value $ChangelogLines
        Set-Content -Path (Join-Path $moduleRoot "$Name.build.ps1") -Value @(
            '. (Get-PlumberTaskLoader) -Config @{}'
        )
        $moduleRoot
    }
}

Describe 'ChangelogUpdated through Invoke-Plumber' {
    It 'passes when a prerelease heading matches the manifest version and prerelease tag' {
        $moduleRoot = New-ChangelogFixtureModule -Name 'PrereleaseChangelogModule' -ManifestLines @(
            '@{'
            "    ModuleVersion = '1.2.0'"
            '    PrivateData   = @{'
            '        PSData = @{'
            "            Prerelease = 'beta.1'"
            '        }'
            '    }'
            '}'
        ) -ChangelogLines @(
            '# Changelog'
            ''
            '## 1.2.0-beta.1'
            '- Changed: example.'
        )

        $result = Invoke-ChangelogTaskRun -ModuleRoot $moduleRoot

        $result.ExitCode | Should -Be 0
        $result.Output | Should -BeLike '*Plumber validation passed*Failed: 0*'
    }

    It 'fails with a clear message when the changelog has no version heading' {
        $moduleRoot = New-ChangelogFixtureModule -Name 'HeadinglessChangelogModule' -ManifestLines @(
            '@{'
            "    ModuleVersion = '1.2.0'"
            '}'
        ) -ChangelogLines @(
            '# Changelog'
            ''
            '- Changed: example without a version heading.'
        )

        $result = Invoke-ChangelogTaskRun -ModuleRoot $moduleRoot

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -BeLike '*Changelog has no version heading*'
    }
}
