<#
    .SYNOPSIS
    Validates PSScriptAnalyzer passes
#>
Add-BuildTask -Name PSScriptAnalyzer -Jobs SetVariables, {
    $scriptFiles = @(
        Get-ChildItem $BuildRoot -File -Recurse |
            Where-Object {$_.Extension -in '.ps1', '.psd1', '.psm1'}
    )

    if (-not $script:PlumberConfig.IncludeTestsInPssa) {
        $testRoot = Join-Path $BuildRoot 'Tests'
        $scriptFiles = @(
            $scriptFiles |
                Where-Object {
                    -not $_.FullName.StartsWith(
                        $testRoot,
                        [System.StringComparison]::OrdinalIgnoreCase
                    )
                }
        )
    }

    $settingsPath = Join-Path $BuildRoot 'PSScriptAnalyzerSettings.psd1'
    $settingsSplat = if (Test-Path $settingsPath) { @{ Settings = $settingsPath } } else { @{} }
    $scriptFailures = foreach ($file in $scriptFiles) {
        try {
            Invoke-ScriptAnalyzer $file.FullName @settingsSplat -ErrorAction Stop
        }
        catch {
            [pscustomobject]@{
                ScriptName = $file.Name
                Line       = 0
                RuleName   = 'InvokeScriptAnalyzer'
                Message    = $_.Exception.Message
            }
        }
    }

    $failures = foreach ($failure in $scriptFailures) {
        (
            "$($failure.ScriptName):$($failure.Line) - " +
            "$($failure.RuleName) - $($failure.Message)"
        )
    }
    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
