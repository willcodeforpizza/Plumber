BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Plumber file cache integration' {
    It 'resets cached files when the task loader is invoked again' {
        $moduleRoot = Join-Path $TestDrive 'CacheResetModule'
        New-Item -Path $moduleRoot -ItemType Directory | Out-Null
        '@{ ModuleVersion = "0.0.1" }' | Set-Content -Path (
            Join-Path $moduleRoot 'CacheResetModule.psd1'
        )
        '$true' | Set-Content -Path (Join-Path $moduleRoot 'Initial.ps1')

        $buildFile = Join-Path $moduleRoot 'cache-reset.build.ps1'
        @(
            'function Add-BuildTask {'
            '    param ('
            '        [string]'
            '        $Name,'
            ''
            '        $Jobs'
            '    )'
            ''
            '    if ($Name -eq "SetVariables") {'
            '        & $Jobs'
            '    }'
            '}'
            'function Write-Build {'
            '    param ($Color, $Message)'
            '    $null = $Color'
            '    $null = $Message'
            '}'
            "Set-Variable -Name BuildRoot -Value '$moduleRoot' -Scope Script"
            "Import-Module '$PSScriptRoot/../../Plumber.psd1' -Force"
            '. (Get-PlumberTaskLoader) -Config @{ ModuleManifest = "CacheResetModule.psd1" }'
            '$first = @(Get-PlumberTaskFile -Task Backticks -Extension ".ps1")'
            "'$true' | Set-Content -Path (Join-Path '$moduleRoot' 'Added.ps1')"
            '. (Get-PlumberTaskLoader) -Config @{ ModuleManifest = "CacheResetModule.psd1" }'
            '$second = @(Get-PlumberTaskFile -Task Backticks -Extension ".ps1")'
            '[pscustomobject]@{'
            '    First = $first.Name'
            '    Second = $second.Name'
            '} | ConvertTo-Json -Compress'
        ) | Set-Content -Path $buildFile

        $result = & pwsh -NoLogo -NoProfile -File $buildFile |
            Select-Object -Last 1 |
                ConvertFrom-Json

        $result.First | Should -Contain 'Initial.ps1'
        $result.First | Should -Not -Contain 'Added.ps1'
        $result.Second | Should -Contain 'Initial.ps1'
        $result.Second | Should -Contain 'Added.ps1'
    }
}
