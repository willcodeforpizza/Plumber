BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }

    # Runs ModuleVersion through a real Invoke-Plumber build in a fresh pwsh
    # process. Invoke-Build promotes task errors, so PSGallery lookup failures
    # need coverage here as well as in the task function unit tests.
    function Invoke-ModuleVersionTaskRun {
        param (
            [string]
            $ModuleRoot
        )

        $modulePath = (Resolve-Path "$PSScriptRoot/../../Plumber.psd1").Path.Replace("'", "''")
        $moduleRootLiteral = $ModuleRoot.Replace("'", "''")
        $command = @"
Import-Module '$modulePath' -Force
Push-Location '$moduleRootLiteral'
Invoke-Plumber -Task ModuleVersion -OutputMode Summary -NoFormat
"@

        $output = & (Get-Command pwsh).Source -NoLogo -NoProfile -Command $command 2>&1 |
            Out-String

        [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = $output
        }
    }

    function New-ModuleVersionFixtureModule {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseShouldProcessForStateChangingFunctions',
            '',
            Justification = 'Creates throwaway TestDrive fixtures only.'
        )]
        [CmdletBinding()]
        param (
            [string]
            $Name,

            [string]
            $FindModuleErrorId,

            [string]
            $FindModuleMessage
        )

        $moduleRoot = Join-Path $TestDrive $Name
        Remove-Item -Path $moduleRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $moduleRoot -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $moduleRoot "$Name.psd1") -Value @(
            '@{'
            "    ModuleVersion = '1.0.0'"
            '}'
        )
        Set-Content -Path (Join-Path $moduleRoot "$Name.build.ps1") -Value @(
            'function Find-Module {'
            '    [CmdletBinding()]'
            '    param ('
            '        [string]'
            '        $Name'
            '    )'
            "    Write-Error -Message '$FindModuleMessage' -ErrorId '$FindModuleErrorId'"
            '}'
            '. (Get-PlumberTaskLoader) -Config @{}'
        )
        $moduleRoot
    }
}

Describe 'ModuleVersion through Invoke-Plumber' {
    It 'reports a gallery query failure instead of not-published in a real build run' {
        $fixtureSplat = @{
            Name              = 'GalleryOutageModule'
            FindModuleErrorId = 'SourceNotFound'
            FindModuleMessage = 'Unable to resolve package source'
        }
        $moduleRoot = New-ModuleVersionFixtureModule @fixtureSplat

        $result = Invoke-ModuleVersionTaskRun -ModuleRoot $moduleRoot

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -BeLike '*Could not query PSGallery for GalleryOutageModule*'
        $result.Output | Should -BeLike '*transient gallery failure*'
        $result.Output | Should -Not -BeLike '*is not published to PSGallery*'
    }
}
